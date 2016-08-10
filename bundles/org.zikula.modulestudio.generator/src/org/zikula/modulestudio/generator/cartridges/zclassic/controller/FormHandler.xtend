package org.zikula.modulestudio.generator.cartridges.zclassic.controller

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.DateField
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.EntityWorkflowType
import de.guite.modulestudio.metamodel.JoinRelationship
import de.guite.modulestudio.metamodel.MappedSuperClass
import de.guite.modulestudio.metamodel.TimeField
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.ConfigLegacy
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.FormLegacy
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.Locking
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.Redirect
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.RelationPresets
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.UploadProcessing
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.form.AutoCompletionRelationTransformer
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.form.ListFieldTransformer
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.Config
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.DeleteEntity
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.EditEntity
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.EntityMetaData
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.AutoCompletionRelationType
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.ColourType
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.DateTypeExtension
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.EntityTreeType
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.GeoType
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.MultiListType
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.TimeTypeExtension
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.UploadTypeExtension
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.field.UserType
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelJoinExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class FormHandler {
    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelJoinExtensions = new ModelJoinExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils
    extension WorkflowExtensions = new WorkflowExtensions

    FileHelper fh = new FileHelper
    Redirect redirectHelper = new Redirect
    RelationPresets relationPresetsHelper = new RelationPresets
    Locking locking = new Locking
    FormLegacy legacyParts = new FormLegacy

    Application app

    /**
     * Entry point for Form handler classes.
     */
    def generate(Application it, IFileSystemAccess fsa) {
        app = it
        if (hasEditActions()) {
            // form handlers
            generateCommon('edit', fsa)
            for (entity : getAllEntities.filter[e|e.hasActions('edit')]) {
                entity.generate('edit', fsa)
            }
            if (!isLegacy) {
                // form types
                for (entity : entities.filter[e|e instanceof MappedSuperClass || e.hasActions('edit')]) {
                    new EditEntity().generate(entity, fsa)
                }
                if (hasMetaDataEntities) {
                    new EntityMetaData().generate(it, fsa)
                }
                if (hasColourFields) {
                    new ColourType().generate(it, fsa)
                }
                if (hasGeographical) {
                    new GeoType().generate(it, fsa)
                }
                if (!getAllEntities.filter[e|!e.fields.filter(DateField).empty].empty) {
                    new DateTypeExtension().generate(it, fsa)
                }
                if (!getAllEntities.filter[e|!e.fields.filter(TimeField).empty].empty) {
                    new TimeTypeExtension().generate(it, fsa)
                }
                if (hasTrees) {
                    new EntityTreeType().generate(it, fsa)
                }
                if (hasUploads) {
                    new UploadTypeExtension().generate(it, fsa)
                }
                if (hasUserFields) {
                    new UserType().generate(it, fsa)
                }
                if (hasMultiListFields) {
                    new MultiListType().generate(it, fsa)
                    new ListFieldTransformer().generate(it, fsa)
                }
                if (needsAutoCompletion) {
                    new AutoCompletionRelationType().generate(it, fsa)
                    new AutoCompletionRelationTransformer().generate(it, fsa)
                }
            }
        }
        if (isLegacy) {
            new ConfigLegacy().generate(it, fsa)
        } else {
            // additional form types
            new DeleteEntity().generate(it, fsa)
            new Config().generate(it, fsa)
        }
    }

    /**
     * Entry point for generic Form handler base classes.
     */
    def private generateCommon(Application it, String actionName, IFileSystemAccess fsa) {
        println('Generating "' + name + '" form handler base class')
        val formHandlerFolder = getAppSourceLibPath + 'Form/Handler/Common/'
        generateClassPair(fsa, formHandlerFolder + actionName.formatForCodeCapital + (if (isLegacy) '' else 'Handler') + '.php',
            fh.phpFileContent(it, formHandlerCommonBaseImpl(actionName)), fh.phpFileContent(app, formHandlerCommonImpl(actionName))
        )
    }

    /**
     * Entry point for Form handler classes per entity.
     */
    def private generate(Entity it, String actionName, IFileSystemAccess fsa) {
        println('Generating form handler classes for "' + name + '_' + actionName + '"')
        val formHandlerFolder = app.getAppSourceLibPath + 'Form/Handler/' + name.formatForCodeCapital + '/'
        app.generateClassPair(fsa, formHandlerFolder + actionName.formatForCodeCapital + (if (app.isLegacy) '' else 'Handler') + '.php',
            fh.phpFileContent(app, formHandlerBaseImpl(actionName)), fh.phpFileContent(app, formHandlerImpl(actionName))
        )
    }

    def private formHandlerCommonBaseImpl(Application it, String actionName) '''
        «IF !isLegacy»
            namespace «appNamespace»\Form\Handler\Common\Base;

            use Symfony\Component\DependencyInjection\ContainerBuilder;
            use Symfony\Component\Form\AbstractType;
            use Symfony\Component\HttpFoundation\RedirectResponse;
            use Symfony\Component\HttpFoundation\Request;
            use Symfony\Component\HttpFoundation\RequestStack;
            use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
            use Symfony\Component\Routing\RouterInterface;
            use Symfony\Component\Security\Core\Exception\AccessDeniedException;
            use Zikula\Common\Translator\TranslatorInterface;
            use Zikula\Common\Translator\TranslatorTrait;
            use Zikula\Core\Doctrine\EntityAccess;
            use Zikula\Core\RouteUrl;
            use ModUtil;
            use RuntimeException;
            use System;
            use UserUtil;
            «IF hasUploads»
                use «appNamespace»\UploadHandler;
            «ENDIF»

        «ENDIF»
        /**
         * This handler class handles the page events of editing forms.
         * It collects common functionality required by different object types.
        «IF isLegacy»
            «legacyParts.handlerDescription»
        «ENDIF»
         */
        «IF isLegacy»
        class «appName»_Form_Handler_Common_Base_«actionName.formatForCodeCapital» extends Zikula_Form_AbstractHandler
        «ELSE»
        class «actionName.formatForCodeCapital»Handler
        «ENDIF»
        {
            «IF !isLegacy»
                use TranslatorTrait;

            «ENDIF»
            /**
             * Name of treated object type.
             *
             * @var string
             */
            protected $objectType;

            /**
             * Name of treated object type starting with upper case.
             *
             * @var string
             */
            protected $objectTypeCapital;

            /**
             * Lower case version.
             *
             * @var string
             */
            protected $objectTypeLower;

            /**
             * Permission component based on object type.
             *
             * @var string
             */
            protected $permissionComponent;

            /**
             * Reference to treated entity instance.
             *
             * @var «IF isLegacy»Zikula_«ELSE»EntityAccess«ENDIF»
             */
            protected $entityRef = null;

            /**
             * List of identifier names.
             *
             * @var array
             */
            protected $idFields = «IF isLegacy»array()«ELSE»[]«ENDIF»;

            /**
             * List of identifiers of treated entity.
             *
             * @var array
             */
            protected $idValues = «IF isLegacy»array()«ELSE»[]«ENDIF»;

            /**
             * Code defining the redirect goal after command handling.
             *
             * @var string
             */
            protected $returnTo = null;

            /**
             * Whether a create action is going to be repeated or not.
             *
             * @var boolean
             */
            protected $repeatCreateAction = false;

            /**
             * Url of current form with all parameters for multiple creations.
             *
             * @var string
             */
            protected $repeatReturnUrl = null;
            «IF !relations.filter(JoinRelationship).empty»
                «relationPresetsHelper.memberFields(it)»

                /**
                 * Full prefix for related items.
                 *
                 * @var string
                 */
                protected $idPrefix = '';
            «ENDIF»

            /**
             * Whether an existing item is used as template for a new one.
             *
             * @var boolean
             */
            protected $hasTemplateId = false;

            «locking.memberVars»
            «IF hasAttributableEntities»

                /**
                 * Whether the entity has attributes or not.
                 *
                 * @var boolean
                 */
                protected $hasAttributes = false;
            «ENDIF»
            «IF !isLegacy && hasSluggable && !getAllEntities.filter[slugUpdatable].empty»

                /**
                 * Whether the entity has an editable slug or not.
                 *
                 * @var boolean
                 */
                protected $hasSlugUpdatableField = false;
            «ENDIF»
            «IF hasTranslatable»

                /**
                 * Whether the entity has translatable fields or not.
                 *
                 * @var boolean
                 */
                protected $hasTranslatableFields = false;
            «ENDIF»
            «IF hasUploads»

                /**
                 * Array with upload field names and mandatory flags.
                 *
                 * @var array
                 */
                protected $uploadFields = «IF isLegacy»array()«ELSE»[]«ENDIF»;
            «ENDIF»
            «IF isLegacy»
                «legacyParts.memberVars(it)»

                «legacyParts.stubs»
            «ELSE»
                /**
                 * @var ContainerBuilder
                 */
                protected $container;

                /**
                 * The current request.
                 *
                 * @var Request
                 */
                protected $request = null;

                /**
                 * The router.
                 *
                 * @var RouterInterface
                 */
                protected $router = null;
                «IF hasUploads»

                    /**
                     * The upload handler.
                     *
                     * @var UploadHandler
                     */
                    protected $uploadHandler = null;
                «ENDIF»

                /**
                 * The handled form type.
                 *
                 * @var AbstractType
                 */
                protected $form = null;

                /**
                 * Template parameters.
                 *
                 * @var array
                 */
                protected $templateParameters = [];

                /**
                 * Constructor.
                 *
                 * @param \Zikula_ServiceManager $serviceManager ServiceManager instance
                 * @param TranslatorInterface    $translator     Translator service instance
                 * @param RequestStack           $requestStack   RequestStack service instance
                 * @param RouterInterface        $router         Router service instance
                «IF hasUploads»
                    «' '»* @param UploadHandler          $uploadHandler  UploadHandler service instance
                «ENDIF»
                 */
                public function __construct(\Zikula_ServiceManager $serviceManager, TranslatorInterface $translator, RequestStack $requestStack, RouterInterface $router«IF hasUploads», UploadHandler $uploadHandler«ENDIF»)
                {
                    $this->container = $serviceManager;
                    $this->setTranslator($translator);
                    $this->request = $requestStack->getCurrentRequest();
                    $this->router = $router;
                    «IF hasUploads»
                        $this->uploadHandler = $uploadHandler;
                    «ENDIF»
                }

                /**
                 * Sets the translator.
                 *
                 * @param TranslatorInterface $translator Translator service instance
                 */
                public function setTranslator(/*TranslatorInterface */$translator)
                {
                    $this->translator = $translator;
                }
            «ENDIF»

            «processForm»
            «IF isLegacy»

                «legacyParts.postInitialise(it, actionName)»
            «ENDIF»

            «redirectHelper.getRedirectCodes(it)»

            «handleCommand»

            «fetchInputData»

            «applyAction»
            «IF needsApproval»

                «prepareWorkflowAdditions»
            «ENDIF»

            «new UploadProcessing().generate(it)»
        }
    '''

    def private dispatch processForm(Application it) '''
        /**
         * Initialise form handler.
         *
         * This method takes care of all necessary initialisation of our data and form states.
         *
        «IF isLegacy»
            «' '»* @param Zikula_Form_View $view The form view instance
        «ELSE»
            «' '»* @param array $templateParameters List of preassigned template variables
        «ENDIF»
         *
         * @return boolean False in case of initialisation errors, otherwise true
         «IF !isLegacy»
         *
         * @throws NotFoundHttpException Thrown if item to be edited isn't found
         * @throws RuntimeException      Thrown if the workflow actions can not be determined
         «ENDIF»
         */
        public function «IF isLegacy»initialize«ELSE»processForm«ENDIF»(«IF isLegacy»Zikula_Form_View $view«ELSE»array $templateParameters«ENDIF»)
        {
            «IF isLegacy»
                $this->inlineUsage = UserUtil::getTheme() == 'Printer' ? true : false;
            «ELSE»
                $this->templateParameters = $templateParameters;
                $this->templateParameters['inlineUsage'] = UserUtil::getTheme() == 'ZikulaPrinterTheme' ? true : false;
            «ENDIF»

            «IF !relations.filter(JoinRelationship).empty»
                «IF isLegacy»
                    $this->idPrefix = $this->request->query->filter('idp', '', FILTER_SANITIZE_STRING);
                «ELSE»
                    $this->idPrefix = $this->request->query->getAlnum('idp', '');
                «ENDIF»
            «ENDIF»

            // initialise redirect goal
            «IF isLegacy»
                $this->returnTo = $this->request->query->filter('returnTo', null, FILTER_SANITIZE_STRING);
            «ELSE»
                $this->returnTo = $this->request->query->getAlnum('returnTo', null);
            «ENDIF»
            // store current uri for repeated creations
            $this->repeatReturnUrl = System::getCurrentURI();

            $this->permissionComponent = «IF isLegacy»$this->name . '«ELSE»'«appName»«ENDIF»:' . $this->objectTypeCapital . ':';

            $this->idFields = ModUtil::apiFunc(«IF isLegacy»$this->name«ELSE»'«appName»'«ENDIF», 'selection', 'getIdFields', «IF isLegacy»array(«ELSE»[«ENDIF»'ot' => $this->objectType«IF isLegacy»)«ELSE»]«ENDIF»);

            // retrieve identifier of the object we wish to view
            «IF isLegacy»
                $controllerHelper = new «app.appName»_Util_Controller($this->view->getServiceManager());
            «ELSE»
                $controllerHelper = $this->container->get('«app.appService».controller_helper');
            «ENDIF»

            $this->idValues = $controllerHelper->retrieveIdentifier($this->request, «IF isLegacy»array()«ELSE»[]«ENDIF», $this->objectType, $this->idFields);
            $hasIdentifier = $controllerHelper->isValidIdentifier($this->idValues);

            $entity = null;
            $this->«IF isLegacy»mode«ELSE»templateParameters['mode']«ENDIF» = $hasIdentifier ? 'edit' : 'create';

            «IF !isLegacy»
                $permissionHelper = $this->container->get('zikula_permissions_module.api.permission');

            «ENDIF»
            if («IF isLegacy»$this->mode«ELSE»$this->templateParameters['mode']«ENDIF» == 'edit') {
                if (!«IF isLegacy»SecurityUtil::check«ELSE»$permissionHelper->has«ENDIF»Permission($this->permissionComponent, $this->createCompositeIdentifier() . '::', ACCESS_EDIT)) {
                    «IF isLegacy»
                        return LogUtil::registerPermissionError();
                    «ELSE»
                        throw new AccessDeniedException();
                    «ENDIF»
                }

                $entity = $this->initEntityForEditing();
                if (!is_object($entity)) {
                    return false;
                }

                «locking.addPageLock(it)»
            } else {
                if (!«IF isLegacy»SecurityUtil::check«ELSE»$permissionHelper->has«ENDIF»Permission($this->permissionComponent, '::', ACCESS_EDIT)) {
                    «IF isLegacy»
                        return LogUtil::registerPermissionError();
                    «ELSE»
                        throw new AccessDeniedException();
                    «ENDIF»
                }

                $entity = $this->initEntityForCreation();
            }

            // save entity reference for later reuse
            $this->entityRef = $entity;

            «initialiseExtensions»

            «IF isLegacy»
                $workflowHelper = new «appName»_Util_Workflow($this->view->getServiceManager());
            «ELSE»
                $workflowHelper = $this->container->get('«appService».workflow_helper');
            «ENDIF»
            $actions = $workflowHelper->getActionsForObject($entity);
            if (false === $actions || !is_array($actions)) {
                «IF isLegacy»
                    return LogUtil::registerError($this->__('Error! Could not determine workflow actions.'));
                «ELSE»
                    $this->request->getSession()->getFlashBag()->add(\Zikula_Session::MESSAGE_ERROR, $this->__('Error! Could not determine workflow actions.'));
                    $logger = $this->container->get('logger');
                    $logArgs = ['app' => '«appName»', 'user' => $this->container->get('zikula_users_module.current_user')->get('uname'), 'entity' => $this->objectType, 'id' => $entity->createCompositeIdentifier()];
                    $logger->error('{app}: User {user} tried to edit the {entity} with id {id}, but failed to determine available workflow actions.', $logArgs);
                    throw new \RuntimeException($this->__('Error! Could not determine workflow actions.'));
                «ENDIF»
            }

            «IF isLegacy»
                $this->view->assign('mode', $this->mode)
                           ->assign('inlineUsage', $this->inlineUsage)
                           ->assign('actions', $actions);
            «ELSE»
                $this->templateParameters['actions'] = $actions;

                $this->form = $this->createForm();
                if (!is_object($this->form)) {
                    return false;
                }

                // handle form request and check validity constraints of $task
                if ($this->form->handleRequest($this->request)->isValid()) {
                    return $this->handleCommand();
                }

                $this->templateParameters['form'] = $this->form->createView();
            «ENDIF»

            // everything okay, no initialisation errors occured
            return true;
        }

        «IF !isLegacy»
            /**
             * Creates the form type.
             */
            protected function createForm()
            {
                // to be customised in sub classes
                return null;
            }
            
            «fh.getterMethod(it, 'templateParameters', 'array', true)»
        «ENDIF»
        «createCompositeIdentifier»

        «initEntityForEditing»

        «initEntityForCreation»
        «initTranslationsForEditing»
        «initAttributesForEditing»
        «IF isLegacy»
            «legacyParts.initCategoriesForEditing(it)»
            «legacyParts.initMetaDataForEditing(it)»
        «ENDIF»
    '''

    def private initialiseExtensions(Application it) '''
        «IF hasAttributableEntities»

            if (true === $this->hasAttributes) {
                $this->initAttributesForEditing();
            }
        «ENDIF»
        «IF hasTranslatable»

            if (true === $this->hasTranslatableFields) {
                $this->initTranslationsForEditing();
            }
        «ENDIF»
        «IF isLegacy»

            «legacyParts.initExtensions(it)»
        «ENDIF»
    '''

    def private createCompositeIdentifier(Application it) '''
        /**
         * Create concatenated identifier string (for composite keys).
         *
         * @return String concatenated identifiers
         */
        protected function createCompositeIdentifier()
        {
            $itemId = '';
            foreach ($this->idFields as $idField) {
                if (!empty($itemId)) {
                    $itemId .= '_';
                }
                $itemId .= $this->idValues[$idField];
            }

            return $itemId;
        }
    '''

    def private initEntityForEditing(Application it) '''
        /**
         * Initialise existing entity for editing.
         *
         * @return «IF isLegacy»Zikula_«ENDIF»EntityAccess|null Desired entity instance or null
         «IF !isLegacy»
         *
         * @throws NotFoundHttpException Thrown if item to be edited isn't found
         «ENDIF»
         */
        protected function initEntityForEditing()
        {
            $entity = ModUtil::apiFunc(«IF isLegacy»$this->name«ELSE»'«appName»'«ENDIF», 'selection', 'getEntity', «IF isLegacy»array(«ELSE»[«ENDIF»'ot' => $this->objectType, 'id' => $this->idValues«IF isLegacy»)«ELSE»]«ENDIF»);
            if (null === $entity) {
                «IF isLegacy»
                    return LogUtil::registerError($this->__('No such item.'));
                «ELSE»
                    throw new NotFoundHttpException($this->__('No such item.'));
                «ENDIF»
            }

            $entity->initWorkflow();

            return $entity;
        }
    '''

    def private initEntityForCreation(Application it) '''
        /**
         * Initialise new entity for creation.
         *
         * @return «IF isLegacy»Zikula_«ENDIF»EntityAccess|null Desired entity instance or null
         «IF !isLegacy»
         *
         * @throws NotFoundHttpException Thrown if item to be cloned isn't found
         «ENDIF»
         */
        protected function initEntityForCreation()
        {
            $this->hasTemplateId = false;
            $templateId = $this->request->query->get('astemplate', '');
            $entity = null;

            if (!empty($templateId)) {
                $templateIdValueParts = explode('_', $templateId);
                $this->hasTemplateId = count($templateIdValueParts) == count($this->idFields);

                if (true === $this->hasTemplateId) {
                    $templateIdValues = «IF isLegacy»array()«ELSE»[]«ENDIF»;
                    $i = 0;
                    foreach ($this->idFields as $idField) {
                        $templateIdValues[$idField] = $templateIdValueParts[$i];
                        $i++;
                    }
                    // reuse existing entity
                    $entityT = ModUtil::apiFunc(«IF isLegacy»$this->name«ELSE»'«appName»'«ENDIF», 'selection', 'getEntity', «IF isLegacy»array(«ELSE»[«ENDIF»'ot' => $this->objectType, 'id' => $templateIdValues«IF isLegacy»)«ELSE»]«ENDIF»);
                    if (null === $entityT) {
                        «IF isLegacy»
                            return LogUtil::registerError($this->__('No such item.'));
                        «ELSE»
                            throw new NotFoundHttpException($this->__('No such item.'));
                        «ENDIF»
                    }
                    $entity = clone $entityT;
                }
            }

            if (is_null($entity)) {
                «IF isLegacy»
                    $entityClass = $this->name . '_Entity_' . ucfirst($this->objectType);
                    $entity = new $entityClass(«/* TODO constructor arguments if required */»);
                «ELSE»
                    $factory = $this->container->get('«appService».' . $this->objectType . '_factory');
                    $createMethod = 'create' . ucfirst($this->objectType);
                    $entity = $factory->$createMethod();
                «ENDIF»
            }

            return $entity;
        }
    '''

    def private initTranslationsForEditing(Application it) '''
        «IF hasTranslatable»

            /**
             * Initialise translations.
             */
            protected function initTranslationsForEditing()
            {
                $entity = $this->entityRef;

                // retrieve translated fields
                «IF isLegacy»
                    $translatableHelper = new «appName»_Util_Translatable($this->view->getServiceManager());
                «ELSE»
                    $translatableHelper = $this->container->get('«app.appService».translatable_helper');
                «ENDIF»
                $translations = $translatableHelper->prepareEntityForEditing($this->objectType, $entity);

                // assign translations
                foreach ($translations as $language => $translationData) {
                    «IF isLegacy»
                        $this->view->assign($this->objectTypeLower . $language, $translationData);
                    «ELSE»
                        $this->templateParameters[$this->objectTypeLower . $language] = $translationData;
                    «ENDIF»
                }

                // assign list of installed languages for translatable extension
                «IF isLegacy»
                    $this->view->assign('supportedLanguages', $translatableHelper->getSupportedLanguages($this->objectType));
                «ELSE»
                    $this->templateParameters['supportedLanguages'] = $translatableHelper->getSupportedLanguages($this->objectType);
                «ENDIF»
            }
        «ENDIF»
    '''

    def private initAttributesForEditing(Application it) '''
        «IF hasAttributableEntities»

            /**
             * Initialise attributes.
             */
            protected function initAttributesForEditing()
            {
                $entity = $this->entityRef;

                $entityData = «IF isLegacy»array()«ELSE»[]«ENDIF»;

                // overwrite attributes array entry with a form compatible format
                $attributes = «IF isLegacy»array()«ELSE»[]«ENDIF»;
                foreach ($this->getAttributeFieldNames() as $fieldName) {
                    $attributes[$fieldName] = $entity->getAttributes()->get($fieldName) ? $entity->getAttributes()->get($fieldName)->getValue() : '';
                }
                $entityData['attributes'] = $attributes;

                «IF isLegacy»
                    $this->view->assign($entityData);
                «ELSE»
                    $this->templateParameters['attributes'] = $this->getAttributeFieldNames();
                «ENDIF»
            }

            /**
             * Return list of attribute field names.
             * To be customised in sub classes as needed.
             *
             * @return array list of attribute names
             */
            protected function getAttributeFieldNames()
            {
                return «IF isLegacy»array(«ELSE»[«ENDIF»
                    'field1', 'field2', 'field3'
                «IF isLegacy»)«ELSE»]«ENDIF»;
            }
        «ENDIF»
    '''

    def private dispatch handleCommand(Application it) '''
        /**
         * Command event handler.
         *
        «IF isLegacy»
            «legacyParts.handleCommandDescription(it)»
        «ELSE»
            «' '»* @param array $args List of arguments
        «ENDIF»
         *
         * @return mixed Redirect or false on errors
         */
        public function handleCommand(«IF isLegacy»Zikula_Form_View $view, «ENDIF»&$args)
        {
            «IF !isLegacy»
                // build $args for BC (e.g. used by redirect handling)
                foreach ($this->templateParameters['actions'] as $action) {
                    if ($this->form->get($action['id'])->isClicked()) {
                        $args['commandName'] = $action['id'];
                    }
                }

            «ENDIF»
            $action = $args['commandName'];
            $isRegularAction = !in_array($action, «IF isLegacy»array(«ELSE»[«ENDIF»'delete'«IF isLegacy», 'cancel')«ELSE», 'reset', 'cancel']«ENDIF»);
            «IF isLegacy»

                if ($isRegularAction) {
                    // do forms validation including checking all validators on the page to validate their input
                    if (!$this->view->isValid()) {
                        return false;
                    }
                }
            «ENDIF»

            if ($isRegularAction || $action == 'delete') {
                $unmappedFormData = $this->fetchInputData(«IF isLegacy»$view, «ENDIF»$args);
                if (false === $unmappedFormData) {
                    return false;
                }
            }

            // get treated entity reference from persisted member var
            $entity = $this->entityRef;
            «IF hasHookSubscribers»

                $hookHelper = null;
                if ($entity->supportsHookSubscribers() && «IF isLegacy»$action != 'cancel'«ELSE»!in_array($action, ['reset', 'cancel'])«ENDIF») {
                    «IF isLegacy»
                        $hookHelper = new «app.appName»_Util_Hook($this->view->getServiceManager());
                    «ELSE»
                        $hookHelper = $this->container->get('«app.appService».hook_helper');
                    «ENDIF»
                    // Let any hooks perform additional validation actions
                    $hookType = $action == 'delete' ? 'validate_delete' : 'validate_edit';
                    $validationHooksPassed = $hookHelper->callValidationHooks($entity, $hookType);
                    if (!$validationHooksPassed) {
                        return false;
                    }
                }
            «ENDIF»
            «IF hasTranslatable»

                if ($isRegularAction && true === $this->hasTranslatableFields) {
                    $this->processTranslationsForUpdate($entity, $unmappedFormData);
                }
            «ENDIF»

            if ($isRegularAction || $action == 'delete') {
                $success = $this->applyAction($args);
                if (!$success) {
                    // the workflow operation failed
                    return false;
                }
                «IF hasHookSubscribers»

                    if ($entity->supportsHookSubscribers()) {
                        // Let any hooks know that we have created, updated or deleted an item
                        $hookType = $action == 'delete' ? 'process_delete' : 'process_edit';
                        $url = null;
                        if ($action != 'delete') {
                            $urlArgs = $entity->createUrlArgs();
                            «IF isLegacy»
                                $url = new Zikula_ModUrl($this->name, FormUtil::getPassedValue('type', 'user', 'GETPOST'), 'display', ZLanguage::getLanguageCode(), $urlArgs);
                            «ELSE»
                                $url = new RouteUrl('«appName.formatForDB»_' . $this->objectType . '_display', $urlArgs);
                            «ENDIF»
                        }
                        if (!is_null($hookHelper)) {
                            $hookHelper->callProcessHooks($entity, $hookType, $url);
                        }
                    }
                «ENDIF»
                «IF isLegacy»

                    «legacyParts.clearCache(it)»
                «ENDIF»
            }

            «locking.releasePageLock(it)»

            «IF isLegacy»
                return $this->view->redirect($this->getRedirectUrl($args));
            «ELSE»
                return new RedirectResponse($this->getRedirectUrl($args), 302);
            «ENDIF»
        }
        «IF hasAttributableEntities»

            /**
             * Prepare update of attributes.
             *
             * @param «IF isLegacy»Zikula_«ENDIF»EntityAccess $entity   currently treated entity instance
             * @param Array«IF isLegacy»       «ENDIF»        $formData form data to be merged
             */
            protected function processAttributesForUpdate($entity, $formData)
            {
                «IF isLegacy»
                    if (!isset($formData['attributes'])) {
                        return;
                    }

                    foreach($formData['attributes'] as $name => $value) {
                        $entity->setAttribute($name, $value);
                    }

                    unset($formData['attributes']);
                «ELSE»
                    foreach ($this->getAttributeFieldNames() as $fieldName) {
                        $value = null;
                        if (isset($formData['attributes' . $fieldName])) {
                            $value = $formData['attributes' . $fieldName];
                            unset($formData['attributes' . $fieldName]);
                        }
                        $entity->setAttribute($fieldName, $value);
                    }
                «ENDIF»
                «/*
                $entity->setAttribute('url', 'http://www.example.com');
                $entity->setAttribute('url', null); // remove
                */»
            }
        «ENDIF»
        «IF hasMetaDataEntities && isLegacy»

            «legacyParts.processMetaDataForUpdate(it)»
        «ENDIF»
        «IF hasTranslatable»

            /**
             * Prepare update of translations.
             *
             * @param «IF isLegacy»Zikula_«ENDIF»EntityAccess $entity   currently treated entity instance
             * @param Array«IF isLegacy»       «ENDIF»        $formData unmapped form data outside the entity scope
             */
            protected function processTranslationsForUpdate($entity, $formData)
            {
                «IF isLegacy»
                    $entityTransClass = $this->name . '_Entity_' . ucfirst($this->objectType) . 'Translation';
                «ELSE»
                    $entityTransClass = '\\«vendor.formatForCodeCapital»\\«name.formatForCodeCapital»Module\\Entity\\' . ucfirst($this->objectType) . 'TranslationEntity';
                «ENDIF»
                $transRepository = $this->entityManager->getRepository($entityTransClass);

                // persist translated fields
                «IF isLegacy»
                    $translatableHelper = new «appName»_Util_Translatable($this->view->getServiceManager());
                «ELSE»
                    $translatableHelper = $this->container->get('«app.appService».translatable_helper');
                «ENDIF»
                $translations = $translatableHelper->processEntityAfterEditing($this->objectType, $formData);

                foreach ($translations as $translation) {
                    foreach ($translation['fields'] as $fieldName => $value) {
                        $transRepository->translate($entity, $fieldName, $translation['locale'], $value);
                    }
                }

                // save updated entity
                $this->entityRef = $entity;
            }
        «ENDIF»

        /**
         * Get success or error message for default operations.
         *
         * @param array   $args    arguments from handleCommand method
         * @param Boolean $success true if this is a success, false for default error
         *
         * @return String desired status or error message
         */
        protected function getDefaultMessage($args, $success = false)
        {
            $message = '';
            switch ($args['commandName']) {
                case 'create':
                    if (true === $success) {
                        $message = $this->__('Done! Item created.');
                    } else {
                        $message = $this->__('Error! Creation attempt failed.');
                    }
                    break;
                case 'update':
                    if (true === $success) {
                        $message = $this->__('Done! Item updated.');
                    } else {
                        $message = $this->__('Error! Update attempt failed.');
                    }
                    break;
                case 'delete':
                    if (true === $success) {
                        $message = $this->__('Done! Item deleted.');
                    } else {
                        $message = $this->__('Error! Deletion attempt failed.');
                    }
                    break;
            }

            return $message;
        }

        /**
         * Add success or error message to session.
         *
         * @param array   $args    arguments from handleCommand method
         * @param Boolean $success true if this is a success, false for default error
         «IF !isLegacy»
         *
         * @throws RuntimeException Thrown if executing the workflow action fails
         «ENDIF»
         */
        protected function addDefaultMessage($args, $success = false)
        {
            $message = $this->getDefaultMessage($args, $success);
            if (empty($message)) {
                return;
            }

            «IF isLegacy»
                if (true === $success) {
                    LogUtil::registerStatus($message);
                } else {
                    LogUtil::registerError($message);
                }
            «ELSE»
                $flashType = true === $success ? \Zikula_Session::MESSAGE_STATUS : \Zikula_Session::MESSAGE_ERROR;
                $this->request->getSession()->getFlashBag()->add($flashType, $message);
                $logger = $this->container->get('logger');
                $logArgs = ['app' => '«appName»', 'user' => $this->container->get('zikula_users_module.current_user')->get('uname'), 'entity' => $this->objectType, 'id' => $this->entityRef->createCompositeIdentifier()];
                if (true === $success) {
                    $logger->notice('{app}: User {user} updated the {entity} with id {id}.', $logArgs);
                } else {
                    $logger->error('{app}: User {user} tried to update the {entity} with id {id}, but failed.', $logArgs);
                }
            «ENDIF»
        }
    '''

    def private fetchInputData(Application it) '''
        /**
         * Input data processing called by handleCommand method.
         *
        «IF isLegacy»
            «' '»* @param Zikula_Form_View $view The form view instance
        «ENDIF»
         * @param array «IF isLegacy»           «ENDIF»$args Additional arguments
         *
         * @return array form data after processing
         */
        public function fetchInputData(«IF isLegacy»Zikula_Form_View $view, «ENDIF»&$args)
        {
            // fetch posted data input values as an associative array
            «IF isLegacy»
                $formData = $this->view->getValues();
                // we want the array with our field values
                $entityData = $formData[$this->objectTypeLower];
                unset($formData[$this->objectTypeLower]);
            «ELSE»
                $formData = $this->form->getData();
            «ENDIF»

            // get treated entity reference from persisted member var
            $entity = $this->entityRef;
            «IF (isLegacy && (hasUserFields || hasListFields)) || hasUploads || (!isLegacy && hasSluggable && !getAllEntities.filter[slugUpdatable].empty)»

                if («IF isLegacy»$args['commandName'] != 'cancel'«ELSE»!in_array($args['commandName'], ['reset', 'cancel'])«ENDIF») {
                    «IF isLegacy»
                        «legacyParts.processSpecialFields(it)»

                    «ENDIF»
                    «IF hasUploads»
                        if (count($this->uploadFields) > 0) {
                            $entityData = $this->handleUploads(«IF isLegacy»$entityData«ELSE»$formData«ENDIF», $entity);
                            if ($entityData == false) {
                                return false;
                            }
                        }

                    «ENDIF»
                    «IF !isLegacy && hasSluggable»
                        if (true === $this->hasSlugUpdatableField && isset($entityData['slug'])) {
                            «IF app.isLegacy»
                                $controllerHelper = new «app.appName»_Util_Controller($this->view->getServiceManager());
                            «ELSE»
                                $controllerHelper = $this->container->get('«app.appService».controller_helper');
                            «ENDIF»
                            $entityData['slug'] = $controllerHelper->formatPermalink($entityData['slug']);
                        }
                    «ENDIF»
                «IF hasUploads && isLegacy»
                } else {
                    «legacyParts.removeAdditionalUploadInformationBeforeMerge(it)»
                «ENDIF»
                }
            «ENDIF»

            «IF isLegacy»
                if (isset($entityData['repeatCreation'])) {
                    if ($this->mode == 'create') {
                        $this->repeatCreateAction = $entityData['repeatCreation'];
                    }
                    unset($entityData['repeatCreation']);
                }
            «ELSE»
                if ($this->templateParameters['mode'] == 'create' && isset($formData['repeatCreation']) && $formData['repeatCreation']) {
                    $this->repeatCreateAction = $formData['repeatCreation'];
                }
            «ENDIF»

            «IF isLegacy»
                if (isset($entityData['additionalNotificationRemarks'])) {
                    SessionUtil::setVar($this->name . 'AdditionalNotificationRemarks', $entityData['additionalNotificationRemarks']);
                    unset($entityData['additionalNotificationRemarks']);
                }
            «ELSE»
                if (isset($formData['additionalNotificationRemarks']) && $formData['additionalNotificationRemarks'] != '') {
                    $this->request->getSession()->set('«appName»AdditionalNotificationRemarks', $formData['additionalNotificationRemarks']);
                }
            «ENDIF»
            «IF hasAttributableEntities»

                if (true === $this->hasAttributes) {
                    $this->processAttributesForUpdate($entity, $formData);
                }
            «ENDIF»
            «IF app.isLegacy»

                «legacyParts.processExtensions(it)»

                // assign fetched data
                $entity->merge($entityData);

                «legacyParts.postMerge(it)»
            «ENDIF»

            // save updated entity
            $this->entityRef = $entity;

            // return remaining form data
            return $formData;
        }
        «IF app.isLegacy»

            «legacyParts.writeRelationDataToEntity(it)»

            «legacyParts.persistRelationData(it)»
        «ENDIF»
    '''

    def private dispatch applyAction(Application it) '''
        /**
         * This method executes a certain workflow action.
         *
         * @param array $args Arguments from handleCommand method
         *
         * @return bool Whether everything worked well or not
         */
        public function applyAction(array $args = «IF isLegacy»array()«ELSE»[]«ENDIF»)
        {
            // stub for subclasses
            return false;
        }
    '''

    def private prepareWorkflowAdditions(Application it) '''
        /**
         * Prepares properties related to advanced workflow.
         *
         * @param bool $enterprise Whether the enterprise workflow is used instead of the standard workflow
        «IF !isLegacy»
            «' '»*
            «' '»* @return array List of additional form options
        «ENDIF»
         */
        protected function prepareWorkflowAdditions($enterprise = false)
        {
            $roles = «IF isLegacy»array()«ELSE»[]«ENDIF»;

            «IF isLegacy»
                $uid = UserUtil::getVar('uid');
            «ELSE»
                $uid = $this->container->get('zikula_users_module.current_user')->get('uid');
            «ENDIF»
            $roles['isCreator'] = $this->entityRef['createdUserId'] == $uid;
            «IF !isLegacy»
                $varHelper = $this->container->get('zikula_extensions_module.api.variable');
            «ENDIF»

            $groupArgs = «IF isLegacy»array(«ELSE»[«ENDIF»'uid' => $uid, 'gid' => «IF isLegacy»$this->getVar(«ELSE»$varHelper->get('«appName»', «ENDIF»'moderationGroupFor' . $this->objectTypeCapital, 2)«IF isLegacy»)«ELSE»]«ENDIF»;
            $roles['isModerator'] = ModUtil::apiFunc('«IF isLegacy»Groups«ELSE»ZikulaGroupsModule«ENDIF»', 'user', 'isgroupmember', $groupArgs);

            if (true === $enterprise) {
                $groupArgs = «IF isLegacy»array(«ELSE»[«ENDIF»'uid' => $uid, 'gid' => «IF isLegacy»$this->getVar(«ELSE»$varHelper->get('«appName»', «ENDIF»'superModerationGroupFor' . $this->objectTypeCapital, 2)«IF isLegacy»)«ELSE»]«ENDIF»;
                $roles['isSuperModerator'] = ModUtil::apiFunc('«IF isLegacy»Groups«ELSE»ZikulaGroupsModule«ENDIF»', 'user', 'isgroupmember', $groupArgs);
            }

            «IF isLegacy»
                $this->view->assign($roles);
            «ELSE»
                return $roles;
            «ENDIF»
        }
    '''

    def private formHandlerCommonImpl(Application it, String actionName) '''
        «IF !isLegacy»
            namespace «appNamespace»\Form\Handler\Common;

            use «appNamespace»\Form\Handler\Common\Base\«actionName.formatForCodeCapital»Handler as Base«actionName.formatForCodeCapital»Handler;

        «ENDIF»
        /**
         * This handler class handles the page events of editing forms.
         * It collects common functionality required by different object types.
         */
        «IF isLegacy»
        class «appName»_Form_Handler_Common_«actionName.formatForCodeCapital» extends «appName»_Form_Handler_Common_Base_«actionName.formatForCodeCapital»
        «ELSE»
        class «actionName.formatForCodeCapital»Handler extends Base«actionName.formatForCodeCapital»Handler
        «ENDIF»
        {
            // feel free to extend the base handler class here
        }
    '''




    def private formHandlerBaseImpl(Entity it, String actionName) '''
        «val app = application»
        «formHandlerBaseImports(actionName)»

        /**
         * This handler class handles the page events of editing forms.
         * It aims on the «name.formatForDisplay» object type.
        «IF app.isLegacy»
            «' '»*
            «' '»* More documentation is provided in the parent class.
        «ENDIF»
         */
        «IF app.isLegacy»
        class «app.appName»_Form_Handler_«name.formatForCodeCapital»_Base_«actionName.formatForCodeCapital» extends «app.appName»_Form_Handler_Common_«actionName.formatForCodeCapital»
        «ELSE»
        class «actionName.formatForCodeCapital»Handler extends Base«actionName.formatForCodeCapital»Handler
        «ENDIF»
        {
            «IF app.isLegacy»
                «formHandlerBasePreInitialise»

            «ENDIF»
            «processForm»

            «IF ownerPermission && standardFields»

                «formHandlerBaseInitEntityForEditing»
            «ENDIF»

            «redirectHelper.getRedirectCodes(it, app)»

            «redirectHelper.getDefaultReturnUrl(it, app)»

            «handleCommand(it)»

            «applyAction(it)»

            «redirectHelper.getRedirectUrl(it, app)»
        }
    '''

    def private formHandlerBaseImports(Entity it, String actionName) '''
        «val app = application»
        «IF !app.isLegacy»
            namespace «app.appNamespace»\Form\Handler\«name.formatForCodeCapital»\Base;

            use «app.appNamespace»\Form\Handler\Common\«actionName.formatForCodeCapital»Handler as Base«actionName.formatForCodeCapital»Handler;

        «ENDIF»
        «locking.imports(it)»
        «IF !app.isLegacy»
            use Symfony\Component\Security\Core\Exception\AccessDeniedException;
            use Symfony\Component\HttpFoundation\RedirectResponse;
            use ModUtil;
            use RuntimeException;
            use System;
            use UserUtil;
        «ENDIF»
    '''

    // 1.3.x only
    def private formHandlerBasePreInitialise(Entity it) '''
        /**
         * Pre-initialise hook.
         *
         * @return void
         */
        public function preInitialize()
        {
            parent::preInitialize();

            «memberVarAssignments»

            «legacyParts.setMemberVars(it)»
        }
    '''

    def private memberVarAssignments(Entity it) '''
        $this->objectType = '«name.formatForCode»';
        $this->objectTypeCapital = '«name.formatForCodeCapital»';
        $this->objectTypeLower = '«name.formatForDB»';

        «locking.memberVarAssignments(it)»
        «IF app.hasAttributableEntities»
            $this->hasAttributes = «attributable.displayBool»;
        «ENDIF»
        «IF app.hasSluggable»
            $this->hasSlugUpdatableField = «(!app.isLegacy && hasSluggableFields && slugUpdatable).displayBool»;
        «ENDIF»
        «IF app.hasTranslatable»
            $this->hasTranslatableFields = «hasTranslatableFields.displayBool»;
        «ENDIF»
        «IF hasUploadFieldsEntity»
            // array with upload fields and mandatory flags
            $this->uploadFields = «IF app.isLegacy»array(«ELSE»[«ENDIF»«FOR uploadField : getUploadFieldsEntity SEPARATOR ', '»'«uploadField.name.formatForCode»' => «uploadField.mandatory.displayBool»«ENDFOR»«IF app.isLegacy»)«ELSE»]«ENDIF»;
        «ENDIF»
    '''

    def private formHandlerBaseInitEntityForEditing(Entity it) '''
        /**
         * Initialise existing entity for editing.
         *
         * @return «IF app.isLegacy»Zikula_«ENDIF»EntityAccess desired entity instance or null
         */
        protected function initEntityForEditing()
        {
            $entity = parent::initEntityForEditing();

            // only allow editing for the owner or people with higher permissions
            «IF app.isLegacy»
                $uid = UserUtil::getVar('uid');
            «ELSE»
                $uid = $this->container->get('zikula_users_module.current_user')->get('uid');
            «ENDIF»
            if (isset($entity['createdUserId']) && $entity['createdUserId'] != $uid) {
                «IF !app.isLegacy»
                    $permissionHelper = $this->container->get('zikula_permissions_module.api.permission');
                «ENDIF»
                if (!«IF app.isLegacy»SecurityUtil::check«ELSE»$permissionHelper->has«ENDIF»Permission($this->permissionComponent, $this->createCompositeIdentifier() . '::', ACCESS_ADD)) {
                    «IF app.isLegacy»
                        return LogUtil::registerPermissionError();
                    «ELSE»
                        throw new AccessDeniedException();
                    «ENDIF»
                }
            }

            return $entity;
        }
    '''

    def private formHandlerImpl(Entity it, String actionName) '''
        «val app = application»
        «IF !app.isLegacy»
            namespace «app.appNamespace»\Form\Handler\«name.formatForCodeCapital»;

            use «app.appNamespace»\Form\Handler\«name.formatForCodeCapital»\Base\«actionName.formatForCodeCapital»Handler as Base«actionName.formatForCodeCapital»Handler;

        «ENDIF»
        /**
         * This handler class handles the page events of the Form called by the «formatForCode(app.appName + '_' + name + '_' + actionName)»() function.
         * It aims on the «name.formatForDisplay» object type.
         */
        «IF app.isLegacy»
        class «app.appName»_Form_Handler_«name.formatForCodeCapital»_«actionName.formatForCodeCapital» extends «app.appName»_Form_Handler_«name.formatForCodeCapital»_Base_«actionName.formatForCodeCapital»
        «ELSE»
        class «actionName.formatForCodeCapital»Handler extends Base«actionName.formatForCodeCapital»Handler
        «ENDIF»
        {
            // feel free to extend the base handler class here
        }
    '''


    def private dispatch processForm(Entity it) '''
        /**
         * Initialise form handler.
         *
         * This method takes care of all necessary initialisation of our data and form states.
         *
        «IF app.isLegacy»
            «' '»* @param Zikula_Form_View $view The form view instance
        «ELSE»
            «' '»* @param array $templateParameters List of preassigned template variables
        «ENDIF»
         *
         * @return boolean False in case of initialisation errors, otherwise true
         */
        public function «IF app.isLegacy»initialize«ELSE»processForm«ENDIF»(«IF app.isLegacy»Zikula_Form_View $view«ELSE»array $templateParameters«ENDIF»)
        {
            «IF !app.isLegacy»
                «memberVarAssignments»

            «ENDIF»
            $result = parent::«IF app.isLegacy»initialize($view)«ELSE»processForm($templateParameters)«ENDIF»;
            if (false === $result) {
                return $result;
            }

            if ($this->«IF app.isLegacy»mode«ELSE»templateParameters['mode']«ENDIF» == 'create') {
                «IF app.isLegacy»
                    $modelHelper = new «app.appName»_Util_Model($this->view->getServiceManager());
                «ELSE»
                    $modelHelper = $this->container->get('«app.appService».model_helper');
                «ENDIF»
                if (!$modelHelper->canBeCreated($this->objectType)) {
                    «IF app.isLegacy»
                        LogUtil::registerError($this->__('Sorry, but you can not create the «name.formatForDisplay» yet as other items are required which must be created before!'));

                        return $this->view->redirect($this->getRedirectUrl(array('commandName' => '')));
                    «ELSE»
                        $this->request->getSession()->getFlashBag()->add(\Zikula_Session::MESSAGE_ERROR, $this->__('Sorry, but you can not create the «name.formatForDisplay» yet as other items are required which must be created before!'));
                        $logger = $this->container->get('logger');
                        $logArgs = ['app' => '«app.appName»', 'user' => $this->container->get('zikula_users_module.current_user')->get('uname'), 'entity' => $this->objectType];
                        $logger->notice('{app}: User {user} tried to create a new {entity}, but failed as it other items are required which must be created before.', $logArgs);

                        return new RedirectResponse($this->getRedirectUrl(['commandName' => '']), 302);
                    «ENDIF»
                }
            }

            $entity = $this->entityRef;
            «locking.setVersion(it)»
            «IF !incoming.empty || !outgoing.empty»
                «relationPresetsHelper.initPresets(it)»
            «ENDIF»

            // save entity reference for later reuse
            $this->entityRef = $entity;

            $entityData = $entity->toArray();
            «IF app.isLegacy && app.hasListFields»

                «legacyParts.initListFields(it)»
            «ENDIF»

            // assign data to template as array (makes translatable support easier)
            «IF app.isLegacy»
                $this->view->assign($this->objectTypeLower, $entityData);
            «ELSE»
                $this->templateParameters[$this->objectTypeLower] = $entityData;
            «ENDIF»
            «IF hasUploadFieldsEntity»

                if ($this->«IF app.isLegacy»mode«ELSE»templateParameters['mode']«ENDIF» == 'edit') {
                    // assign formatted title (used for image thumbnails)
                    «IF app.isLegacy»
                        $this->view->assign('formattedEntityTitle', $entity->getTitleFromDisplayPattern());
                    «ELSE»
                        $this->templateParameters['formattedEntityTitle'] = $entity->getTitleFromDisplayPattern();
                    «ENDIF»
                }
            «ENDIF»
            «IF app.isLegacy && workflow != EntityWorkflowType.NONE»

                $this->prepareWorkflowAdditions(«(workflow == EntityWorkflowType.ENTERPRISE).displayBool»);
            «ENDIF»

            // everything okay, no initialisation errors occured
            return true;
        }
        «IF !app.isLegacy»

            /**
             * Creates the form type.
             */
            protected function createForm()
            {
                $options = [
                    'mode' => $this->templateParameters['mode'],
                    'actions' => $this->templateParameters['actions'],
                    «IF attributable»
                        'attributes' => $this->templateParameters['attributes'],
                    «ENDIF»
                    «IF !incoming.empty || !outgoing.empty»
                        'inlineUsage' => $this->templateParameters['inlineUsage']
                    «ENDIF»
                ];
                «IF !app.isLegacy && workflow != EntityWorkflowType.NONE»

                    $workflowRoles = $this->prepareWorkflowAdditions(«(workflow == EntityWorkflowType.ENTERPRISE).displayBool»);
                    $options = array_merge($options, $workflowRoles);
                «ENDIF»

                return $this->container->get('form.factory')->create('«app.appNamespace»\Form\Type\«name.formatForCodeCapital»Type', $this->entityRef, $options);
            }
        «ENDIF»
    '''

    def private dispatch handleCommand(Entity it) '''
        /**
         * Command event handler.
         *
         * This event handler is called when a command is issued by the user.
         *
        «IF app.isLegacy»
            «' '»* @param Zikula_Form_View $view The form view instance
            «' '»* @param array            $args Additional arguments
        «ELSE»
            «' '»* @param array $args List of arguments
        «ENDIF»
         *
         * @return mixed Redirect or false on errors
         */
        public function handleCommand(«IF app.isLegacy»Zikula_Form_View $view, «ENDIF»&$args)
        {
            $result = parent::handleCommand(«IF app.isLegacy»$view, «ENDIF»$args);
            if (false === $result) {
                return $result;
            }

            «IF app.isLegacy»
                return $this->view->redirect($this->getRedirectUrl($args));
            «ELSE»
                return new RedirectResponse($this->getRedirectUrl($args), 302);
            «ENDIF»
        }

        /**
         * Get success or error message for default operations.
         *
         * @param array   $args    Arguments from handleCommand method
         * @param Boolean $success Becomes true if this is a success, false for default error
         *
         * @return String desired status or error message
         */
        protected function getDefaultMessage($args, $success = false)
        {
            if (false === $success) {
                return parent::getDefaultMessage($args, $success);
            }

            $message = '';
            switch ($args['commandName']) {
                «IF app.hasWorkflowState('deferred')»
                    case 'defer':
                «ENDIF»
                case 'submit':
                    if ($this->«IF app.isLegacy»mode«ELSE»templateParameters['mode']«ENDIF» == 'create') {
                        $message = $this->__('Done! «name.formatForDisplayCapital» created.');
                    } else {
                        $message = $this->__('Done! «name.formatForDisplayCapital» updated.');
                    }
                    break;
                case 'delete':
                    $message = $this->__('Done! «name.formatForDisplayCapital» deleted.');
                    break;
                default:
                    $message = $this->__('Done! «name.formatForDisplayCapital» updated.');
                    break;
            }

            return $message;
        }
    '''

    def private dispatch applyAction(Entity it) '''
        /**
         * This method executes a certain workflow action.
         *
         * @param array $args Arguments from handleCommand method
         *
         * @return bool Whether everything worked well or not
         «IF !app.isLegacy»
         *
         * @throws RuntimeException Thrown if concurrent editing is recognised or another error occurs
         «ENDIF»
         */
        public function applyAction(array $args = «IF app.isLegacy»array()«ELSE»[]«ENDIF»)
        {
            // get treated entity reference from persisted member var
            $entity = $this->entityRef;
            «IF app.isLegacy»

                if (!$entity->validate()) {
                    return false;
                }
            «ENDIF»

            $action = $args['commandName'];
            «locking.getVersion(it)»

            $success = false;
            «IF !app.isLegacy»
                $flashBag = $this->request->getSession()->getFlashBag();
                $logger = $this->container->get('logger');
            «ENDIF»
            try {
                «locking.applyLock(it)»
                // execute the workflow action
                «IF app.isLegacy»
                    $workflowHelper = new «app.appName»_Util_Workflow($this->view->getServiceManager());
                «ELSE»
                    $workflowHelper = $this->container->get('«app.appService».workflow_helper');
                «ENDIF»
                $success = $workflowHelper->executeAction($entity, $action);
            «locking.catchException(it)»
            } catch(\Exception $e) {
                «IF app.isLegacy»
                    LogUtil::registerError($this->__f('Sorry, but an unknown error occured during the %s action. Please apply the changes again!', array($action)));
                «ELSE»
                    $flashBag->add(\Zikula_Session::MESSAGE_ERROR, $this->__f('Sorry, but an unknown error occured during the %action% action. Please apply the changes again!', ['%action%' => $action]));
                    $logArgs = ['app' => '«app.appName»', 'user' => $this->container->get('zikula_users_module.current_user')->get('uname'), 'entity' => '«name.formatForDisplay»', 'id' => $entity->createCompositeIdentifier(), 'errorMessage' => $e->getMessage()];
                    $logger->error('{app}: User {user} tried to edit the {entity} with id {id}, but failed. Error details: {errorMessage}.', $logArgs);
                «ENDIF»
            }

            $this->addDefaultMessage($args, $success);

            if ($success && $this->«IF app.isLegacy»mode«ELSE»templateParameters['mode']«ENDIF» == 'create') {
                // store new identifier
                foreach ($this->idFields as $idField) {
                    $this->idValues[$idField] = $entity[$idField];
                }
            }
            «IF !incoming.empty || !outgoing.empty»
                «relationPresetsHelper.saveNonEditablePresets(it, app)»
            «ENDIF»

            return $success;
        }
    '''

    def private isLegacy(Application it) {
        targets('1.3.x')
    }
}