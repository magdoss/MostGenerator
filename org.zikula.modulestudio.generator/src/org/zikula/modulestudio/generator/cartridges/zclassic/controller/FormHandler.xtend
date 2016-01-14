package org.zikula.modulestudio.generator.cartridges.zclassic.controller

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.DateField
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.EntityWorkflowType
import de.guite.modulestudio.metamodel.TimeField
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.ConfigLegacy
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.FormLegacy
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.Redirect
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.RelationPresets
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionhandler.UploadProcessing
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.form.ListFieldTransformer
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.Config
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.DeleteEntity
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.EditEntity
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.EntityMetaData
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
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class FormHandler {
    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils
    extension WorkflowExtensions = new WorkflowExtensions

    FileHelper fh = new FileHelper
    Redirect redirectHelper = new Redirect
    RelationPresets relationPresetsHelper = new RelationPresets
    FormLegacy legacyParts = new FormLegacy

    Application app

    /* TODO migrate to Symfony forms #416 */

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
                for (entity : getAllEntities.filter[e|e.hasActions('edit')]) {
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
            use Symfony\Component\HttpFoundation\RequestStack;
            use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
            use Symfony\Component\Routing\Router;
            use Symfony\Component\Security\Core\Exception\AccessDeniedException;
            «IF hasUploads»
                use «appNamespace»\UploadHandler;
            «ENDIF»

            use ModUtil;
            use System;
            use UserUtil;
            use ZLanguage;
            use Zikula\Core\RouteUrl;

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
             * @var Zikula_EntityAccess
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
            «relationPresetsHelper.memberFields(it)»

            /**
             * One of "create" or "edit".
             *
             * @var string
             */
            protected $mode;

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

            /**
             * Whether this form is being used inline within a window.
             *
             * @var boolean
             */
            protected $inlineUsage = false;

            /**
             * Full prefix for related items.
             *
             * @var string
             */
            protected $idPrefix = '';

            /**
             * Whether an existing item is used as template for a new one.
             *
             * @var boolean
             */
            protected $hasTemplateId = false;

            /**
             * Whether the PageLock extension is used for this entity type or not.
             *
             * @var boolean
             */
            protected $hasPageLockSupport = false;
            «IF hasAttributableEntities»

                /**
                 * Whether the entity has attributes or not.
                 *
                 * @var boolean
                 */
                protected $hasAttributes = false;
            «ENDIF»
            «IF hasSluggable»

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
                 * @var Router
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
                 * Constructor.
                 *
                 * @param \Zikula_ServiceManager $serviceManager ServiceManager instance.
                 * @param RequestStack           $requestStack   RequestStack service instance.
                 * @param Router                 $router         Router service instance.
                «IF hasUploads»
                    «' '»* @param UploadHandler          $uploadHandler  UploadHandler service instance.
                «ENDIF»
                 */
                public function __construct(\Zikula_ServiceManager $serviceManager, RequestStack $requestStack, Router $router«IF hasUploads», UploadHandler $uploadHandler«ENDIF»)
                {
                    $this->container = $serviceManager;
                    $this->request = $requestStack->getCurrentRequest();
                    $this->router = $router;
                    «IF hasUploads»
                        $this->uploadHandler = $uploadHandler;
                    «ENDIF»
                }


«/* TODO





    $form = $this->createForm('...\MyType', $mode != 'create' ? $task : null);

    // handle form request and check validity constraints of $task
    if ($form->handleRequest($request)->isValid()) {
        // check if form has been submitted (independent of validity)
        $isSubmitted = $form->isSubmitted();

        // access field data in controller
        $form->get('dueDate')->getData();

        // change data of unmapped field
        $form->get('addition')->setData('My custom value');

        // access original task object (if it is somehow not available)
        $task = $form->getData();

        // persist the task with new data
        $em = $this->getDoctrine()->getManager();
        $em->persist($task);
        $em->flush();

        // check which button has been clicked
        $nextAction = $form->get('saveAndAdd')->isClicked()
            ? 'task_new'
            : 'task_success';

        return $this->redirectToRoute($router->generate($nextAction));
    }


$this->templateParameters
  processForm($templateParameters) -> set
  getTemplateParameters() -> get


required form options
'mode' -> create or edit
if attributable
    attributes
if (workflow != none)
    isModerator
    isSuperModerator
    isCreator
'actions' -> list of workflow actions
inlineUsage => false/true

required template vars
'«entity.name.formatForDB»' -> entity instance
'mode' -> create or edit
'form' -> $form->createView()
'actions' -> list of workflow actions
if attributable:
    attributes -> list of fieldNames
 */»

            «ENDIF»

            «initialize(actionName)»

            /**
             * Post-initialise hook.
             *
             * @return void
             */
            public function postInitialize()
            {
                «IF isLegacy»
                    $entityClass = $this->name . '_Entity_' . ucfirst($this->objectType);
                    $repository = $this->entityManager->getRepository($entityClass);
                «ELSE»
                    $repository = $this->container->get('«appName.formatForDB».' . $this->objectType . '_factory')->getRepository();
                «ENDIF»
                $utilArgs = «IF isLegacy»array(«ELSE»[«ENDIF»
                    'controller' => \FormUtil::getPassedValue('type', 'user', 'GETPOST'),
                    'action' => '«actionName.formatForCode.toFirstLower»',
                    'mode' => $this->mode
                «IF isLegacy»)«ELSE»]«ENDIF»;
                $this->view->assign($repository->getAdditionalTemplateParameters('controllerAction', $utilArgs));
            }

            «redirectHelper.getRedirectCodes(it, actionName)»

            «handleCommand(actionName)»

            «fetchInputData(actionName)»

            «applyAction(actionName)»

            «new UploadProcessing().generate(it)»
        }
    '''

    def private initialize(Application it, String actionName) '''
        /**
         * Initialize form handler.
         *
         * This method takes care of all necessary initialisation of our data and form states.
         *
         * @param Zikula_Form_View $view The form view instance.
         *
         * @return boolean False in case of initialization errors, otherwise true.
         «IF !isLegacy»
         *
         * @throws NotFoundHttpException Thrown if item to be edited isn't found
         * @throws RuntimeException      Thrown if the workflow actions can not be determined
         «ENDIF»
         */
        public function initialize(Zikula_Form_View $view)
        {
            $this->inlineUsage = UserUtil::getTheme() == '«IF isLegacy»Printer«ELSE»ZikulaPrinterTheme«ENDIF»' ? true : false;
            «IF isLegacy»
                $this->idPrefix = $this->request->query->filter('idp', '', FILTER_SANITIZE_STRING);
            «ELSE»
                $this->idPrefix = $this->request->query->getAlnum('idp', '');
            «ENDIF»

            // initialise redirect goal
            «IF isLegacy»
                $this->returnTo = $this->request->query->filter('returnTo', null, FILTER_SANITIZE_STRING);
            «ELSE»
                $this->returnTo = $this->request->query->getAlnum('returnTo', null);
            «ENDIF»
            // store current uri for repeated creations
            $this->repeatReturnUrl = System::getCurrentURI();

            $this->permissionComponent = $this->name . ':' . $this->objectTypeCapital . ':';

            «IF isLegacy»
                $entityClass = $this->name . '_Entity_' . ucfirst($this->objectType);
            «ELSE»
                $entityClass = '«vendor.formatForCodeCapital»«name.formatForCodeCapital»Module:' . ucfirst($this->objectType) . 'Entity';
            «ENDIF»
            $this->idFields = ModUtil::apiFunc($this->name, 'selection', 'getIdFields', «IF isLegacy»array(«ELSE»[«ENDIF»'ot' => $this->objectType«IF isLegacy»)«ELSE»]«ENDIF»);

            // retrieve identifier of the object we wish to view
            «IF app.isLegacy»
                $controllerHelper = new «app.appName»_Util_Controller($this->view->getServiceManager());
            «ELSE»
                $controllerHelper = $this->container->get('«app.appName.formatForDB».controller_helper');
            «ENDIF»

            $this->idValues = $controllerHelper->retrieveIdentifier($this->request, «IF isLegacy»array()«ELSE»[]«ENDIF», $this->objectType, $this->idFields);
            $hasIdentifier = $controllerHelper->isValidIdentifier($this->idValues);

            $entity = null;
            $this->mode = ($hasIdentifier) ? 'edit' : 'create';

            «IF !app.isLegacy»
                $permissionHelper = $this->container->get('zikula_permissions_module.api.permission');

            «ENDIF»
            if ($this->mode == 'edit') {
                if (!«IF app.isLegacy»SecurityUtil::check«ELSE»$permissionHelper->has«ENDIF»Permission($this->permissionComponent, $this->createCompositeIdentifier() . '::', ACCESS_EDIT)) {
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

                if ($this->hasPageLockSupport === true && ModUtil::available('«IF isLegacy»PageLock«ELSE»ZikulaPageLockModule«ENDIF»')) {
                    // try to guarantee that only one person at a time can be editing this entity
                    ModUtil::apiFunc('«IF isLegacy»PageLock«ELSE»ZikulaPageLockModule«ENDIF»', 'user', 'pageLock', «IF isLegacy»array(«ELSE»[«ENDIF»
                                         'lockName' => «IF isLegacy»$this->name«ELSE»'«app.appName»'«ENDIF» . $this->objectTypeCapital . $this->createCompositeIdentifier(),
                                         'returnUrl' => $this->getRedirectUrl(null)
                    «IF isLegacy»)«ELSE»]«ENDIF»);
                }
            } else {
                if (!«IF app.isLegacy»SecurityUtil::check«ELSE»$permissionHelper->has«ENDIF»Permission($this->permissionComponent, '::', ACCESS_EDIT)) {
                    «IF isLegacy»
                        return LogUtil::registerPermissionError();
                    «ELSE»
                        throw new AccessDeniedException();
                    «ENDIF»
                }

                $entity = $this->initEntityForCreation();
            }

            $this->view->assign('mode', $this->mode)
                       ->assign('inlineUsage', $this->inlineUsage);

            // save entity reference for later reuse
            $this->entityRef = $entity;

            «initializeExtensions»

            «IF isLegacy»
                $workflowHelper = new «appName»_Util_Workflow($this->view->getServiceManager());
            «ELSE»
                $workflowHelper = $this->container->get('«appName.formatForDB».workflow_helper');
            «ENDIF»
            $actions = $workflowHelper->getActionsForObject($entity);
            if ($actions === false || !is_array($actions)) {
                «IF isLegacy»
                    return LogUtil::registerError($this->__('Error! Could not determine workflow actions.'));
                «ELSE»
                    $this->request->getSession()->getFlashBag()->add(\Zikula_Session::MESSAGE_ERROR, $this->__('Error! Could not determine workflow actions.'));
                    $logger = $this->container->get('logger');
                    $logger->error('{app}: User {user} tried to edit the {entity} with id {id}, but failed to determine available workflow actions.', ['app' => '«app.appName»', 'user' => UserUtil::getVar('uname'), 'entity' => $this->objectType, 'id' => $entity->createCompositeIdentifier()]);
                    throw new \RuntimeException($this->__('Error! Could not determine workflow actions.'));
                «ENDIF»
            }
            // assign list of allowed actions to the view for further processing
            $this->view->assign('actions', $actions);

            // everything okay, no initialization errors occured
            return true;
        }

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

    def private initializeExtensions(Application it) '''
        «IF hasAttributableEntities»

            if ($this->hasAttributes === true) {
                $this->initAttributesForEditing();
            }
        «ENDIF»
        «IF hasTranslatable»

            if ($this->hasTranslatableFields === true) {
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
         * @return String concatenated identifiers. 
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
         * @return Zikula_EntityAccess desired entity instance or null
         «IF !isLegacy»
         *
         * @throws NotFoundHttpException Thrown if item to be edited isn't found
         «ENDIF»
         */
        protected function initEntityForEditing()
        {
            $entity = ModUtil::apiFunc($this->name, 'selection', 'getEntity', «IF isLegacy»array(«ELSE»[«ENDIF»'ot' => $this->objectType, 'id' => $this->idValues«IF isLegacy»)«ELSE»]«ENDIF»);
            if ($entity == null) {
                «IF isLegacy»return LogUtil::registerError«ELSE»throw new NotFoundHttpException«ENDIF»($this->__('No such item.'));
            }

            $entity->initWorkflow();

            return $entity;
        }
    '''

    def private initEntityForCreation(Application it) '''
        /**
         * Initialise new entity for creation.
         *
         * @return Zikula_EntityAccess desired entity instance or null
         «IF !isLegacy»
         *
         * @throws NotFoundHttpException Thrown if item to be cloned isn't found
         «ENDIF»
         */
        protected function initEntityForCreation()
        {
            $this->hasTemplateId = false;
            $templateId = $this->request->query->get('astemplate', '');
            if (!empty($templateId)) {
                $templateIdValueParts = explode('_', $templateId);
                $this->hasTemplateId = (count($templateIdValueParts) == count($this->idFields));
            }

            if ($this->hasTemplateId === true) {
                $templateIdValues = «IF isLegacy»array()«ELSE»[]«ENDIF»;
                $i = 0;
                foreach ($this->idFields as $idField) {
                    $templateIdValues[$idField] = $templateIdValueParts[$i];
                    $i++;
                }
                // reuse existing entity
                $entityT = ModUtil::apiFunc($this->name, 'selection', 'getEntity', «IF isLegacy»array(«ELSE»[«ENDIF»'ot' => $this->objectType, 'id' => $templateIdValues«IF isLegacy»)«ELSE»]«ENDIF»);
                if ($entityT == null) {
                    «IF isLegacy»return LogUtil::registerError«ELSE»throw new NotFoundHttpException«ENDIF»($this->__('No such item.'));
                }
                $entity = clone $entityT;
            } else {
                «IF isLegacy»
                    $entityClass = $this->name . '_Entity_' . ucfirst($this->objectType);
                    $entity = new $entityClass(«/* TODO constructor arguments if required */»);
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
                    $translatableHelper = $this->container->get('«app.appName.formatForDB».translatable_helper');
                «ENDIF»
                $translations = $translatableHelper->prepareEntityForEditing($this->objectType, $entity);

                // assign translations
                foreach ($translations as $language => $translationData) {
                    $this->view->assign($this->objectTypeLower . $language, $translationData);
                }

                // assign list of installed languages for translatable extension
                $this->view->assign('supportedLanguages', $translatableHelper->getSupportedLanguages($this->objectType));
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

                $entityData = «IF isLegacy»array()«ELSE»[]«ENDIF»;«/*$entity->toArray(); not required probably*/»

                // overwrite attributes array entry with a form compatible format
                $attributes = «IF isLegacy»array()«ELSE»[]«ENDIF»;
                foreach ($this->getAttributeFieldNames() as $fieldName) {
                    $attributes[$fieldName] = $entity->getAttributes()->get($fieldName) ? $entity->getAttributes()->get($fieldName)->getValue() : '';
                }
                $entityData['attributes'] = $attributes;

                $this->view->assign($entityData);
            }

            /**
             * Return list of attribute field names.
             *
             * @return array list of attribute names.
             */
            protected function getAttributeFieldNames()
            {
                return «IF isLegacy»array(«ELSE»[«ENDIF»
                    'field1', 'field2', 'field3'
                «IF isLegacy»)«ELSE»]«ENDIF»;
            }
        «ENDIF»
    '''

    def private handleCommand(Application it, String actionName) '''
        /**
         * Command event handler.
         *
         * This event handler is called when a command is issued by the user. Commands are typically something
         * that originates from a {@link Zikula_Form_Plugin_Button} plugin. The passed args contains different properties
         * depending on the command source, but you should at least find a <var>$args['commandName']</var>
         * value indicating the name of the command. The command name is normally specified by the plugin
         * that initiated the command.
         *
         * @param Zikula_Form_View $view The form view instance.
         * @param array            $args Additional arguments.
         *
         * @see Zikula_Form_Plugin_Button
         * @see Zikula_Form_Plugin_ImageButton
         *
         * @return mixed Redirect or false on errors.
         */
        public function handleCommand(Zikula_Form_View $view, &$args)
        {
            «IF !isLegacy»
                «/* TODO: fix implementation */»
                // build $args for BC (e.g. used by handleInlineRedirect)
                $args = [];
                foreach ($actions as $actions) {
                    if ($form->get($action['id'])->isClicked()) {
                        $args['commandName'] = $action['id'];
                    }
                }

            «ENDIF»
            $action = $args['commandName'];
            $isRegularAction = !in_array($action, «IF isLegacy»array(«ELSE»[«ENDIF»'delete'«IF isLegacy», 'cancel')«ELSE», 'reset', 'cancel']«ENDIF»);

            if ($isRegularAction) {
                // do forms validation including checking all validators on the page to validate their input
                if (!$this->view->isValid()) {
                    return false;
                }
            }

            if («IF isLegacy»$action != 'cancel'«ELSE»!in_array($action, ['reset', 'cancel'])«ENDIF») {
                $otherFormData = $this->fetchInputData($view, $args);
                if ($otherFormData === false) {
                    return false;
                }
            }

            // get treated entity reference from persisted member var
            $entity = $this->entityRef;
            «IF hasHookSubscribers»

                if ($entity->supportsHookSubscribers() && «IF isLegacy»$action != 'cancel'«ELSE»!in_array($action, ['reset', 'cancel'])«ENDIF») {
                    «IF isLegacy»
                        $hookHelper = new «app.appName»_Util_Hook($this->view->getServiceManager());
                    «ELSE»
                        $hookHelper = $this->container->get('«app.appName.formatForDB».hook_helper');
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

                if ($isRegularAction && $this->hasTranslatableFields === true) {
                    $this->processTranslationsForUpdate($entity, $otherFormData);
                }
            «ENDIF»

            if («IF isLegacy»$action != 'cancel'«ELSE»!in_array($action, ['reset', 'cancel'])«ENDIF») {
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
                        $hookHelper->callProcessHooks($entity, $hookType, $url);
                    }
                «ENDIF»
                «IF isLegacy»

                    // An item was created, updated or deleted, so we clear all cached pages for this item.
                    $cacheArgs = array('ot' => $this->objectType, 'item' => $entity);
                    ModUtil::apiFunc($this->name, 'cache', 'clearItemCache', $cacheArgs);

                    // clear view cache to reflect our changes
                    $this->view->clear_cache();
                «ENDIF»
            }

            if ($this->hasPageLockSupport === true && $this->mode == 'edit' && ModUtil::available('«IF isLegacy»PageLock«ELSE»ZikulaPageLockModule«ENDIF»')) {
                ModUtil::apiFunc('«IF isLegacy»PageLock«ELSE»ZikulaPageLockModule«ENDIF»', 'user', 'releaseLock', «IF isLegacy»array(«ELSE»[«ENDIF»
                                     'lockName' => «IF isLegacy»$this->name«ELSE»'«app.appName»'«ENDIF» . $this->objectTypeCapital . $this->createCompositeIdentifier()
                «IF isLegacy»)«ELSE»]«ENDIF»);
            }

            return $this->view->redirect($this->getRedirectUrl($args));
        }
        «IF hasAttributableEntities»

            /**
             * Prepare update of attributes.
             *
             * @param Zikula_EntityAccess $entity   currently treated entity instance.
             * @param Array               $formData form data to be merged.
             */
            protected function processAttributesForUpdate($entity, $formData)
            {
                if (!isset($formData['attributes'])) {
                    return;
                }

                foreach($formData['attributes'] as $name => $value) {
                    $entity->setAttribute($name, $value);
                }
                «/*
                $entity->setAttribute('url', 'http://www.example.com');
                $entity->setAttribute('url', null); // remove
                */»
                unset($formData['attributes']);
            }
        «ENDIF»
        «IF hasMetaDataEntities && isLegacy»

            «legacyParts.processMetaDataForUpdate(it)»
        «ENDIF»
        «IF hasTranslatable»

            /**
             * Prepare update of translations.
             *
             * @param Zikula_EntityAccess $entity   currently treated entity instance.
             * @param Array               $formData additional form data outside the entity scope.
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
                    $translatableHelper = $this->container->get('«app.appName.formatForDB».translatable_helper');
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
         * @param Array   $args    arguments from handleCommand method.
         * @param Boolean $success true if this is a success, false for default error.
         * @return String desired status or error message.
         */
        protected function getDefaultMessage($args, $success = false)
        {
            $message = '';
            switch ($args['commandName']) {
                case 'create':
                        if ($success === true) {
                            $message = $this->__('Done! Item created.');
                        } else {
                            $message = $this->__('Error! Creation attempt failed.');
                        }
                        break;
                case 'update':
                        if ($success === true) {
                            $message = $this->__('Done! Item updated.');
                        } else {
                            $message = $this->__('Error! Update attempt failed.');
                        }
                        break;
                case 'delete':
                        if ($success === true) {
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
         * @param Array   $args    arguments from handleCommand method.
         * @param Boolean $success true if this is a success, false for default error.
         «IF !isLegacy»
         *
         * @throws RuntimeException Thrown if executing the workflow action fails
         «ENDIF»
         */
        protected function addDefaultMessage($args, $success = false)
        {
            $message = $this->getDefaultMessage($args, $success);
            if (!empty($message)) {
                «IF isLegacy»
                    if ($success === true) {
                        LogUtil::registerStatus($message);
                    } else {
                        LogUtil::registerError($message);
                    }
                «ELSE»
                    $flashType = ($success === true) ? \Zikula_Session::MESSAGE_STATUS : \Zikula_Session::MESSAGE_ERROR;
                    $this->request->getSession()->getFlashBag()->add($flashType, $message);
                    $logger = $this->container->get('logger');
                    $logArgs = ['app' => '«app.appName»', 'user' => UserUtil::getVar('uname'), 'entity' => $this->objectType, 'id' => $this->entityRef->createCompositeIdentifier()];
                    if ($success === true) {
                        $logger->notice('{app}: User {user} updated the {entity} with id {id}.', $logArgs);
                    } else {
                        $logger->error('{app}: User {user} tried to update the {entity} with id {id}, but failed.', $logArgs);
                    }
                «ENDIF»
            }
        }
    '''

    def private fetchInputData(Application it, String actionName) '''
        /**
         * Input data processing called by handleCommand method.
         *
         * @param Zikula_Form_View $view The form view instance.
         * @param array            $args Additional arguments.
         *
         * @return array form data after processing.
         */
        public function fetchInputData(Zikula_Form_View $view, &$args)
        {
            // fetch posted data input values as an associative array
            $formData = $this->view->getValues();
            // we want the array with our field values
            $entityData = $formData[$this->objectTypeLower];
            unset($formData[$this->objectTypeLower]);

            // get treated entity reference from persisted member var
            $entity = $this->entityRef;

            «IF (isLegacy && hasUserFields) || hasUploads || (isLegacy && hasListFields) || (hasSluggable && !getAllEntities.filter[slugUpdatable].empty)»

                if («IF isLegacy»$args['commandName'] != 'cancel'«ELSE»!in_array($args['commandName, ['reset', 'cancel'])«ENDIF») {
                    «IF isLegacy»
                        «legacyParts.processSpecialFields(it)»

                    «ENDIF»
                    «IF hasUploads»
                        if (count($this->uploadFields) > 0) {
                            $entityData = $this->handleUploads($entityData, $entity);
                            if ($entityData == false) {
                                return false;
                            }
                        }

                    «ENDIF»
                    «IF !isLegacy && hasSluggable»
                        if ($this->hasSlugUpdatableField === true && isset($entityData['slug'])) {
                            «IF app.isLegacy»
                                $controllerHelper = new «app.appName»_Util_Controller($this->view->getServiceManager());
                            «ELSE»
                                $controllerHelper = $this->container->get('«app.appName.formatForDB».controller_helper');
                            «ENDIF»
                            $entityData['slug'] = $controllerHelper->formatPermalink($entityData['slug']);
                        }
                    «ENDIF»
                «IF hasUploads»
                } else {
                    // remove fields for form options to prevent them being merged into the entity object
                    if (count($this->uploadFields) > 0) {
                        foreach ($this->uploadFields as $uploadField => $isMandatory) {
                            if (isset($entityData[$uploadField . 'DeleteFile'])) {
                                unset($entityData[$uploadField . 'DeleteFile']);
                            }
                        }
                    }
                «ENDIF»
                }
            «ENDIF»

            if (isset($entityData['repeatCreation'])) {
                if ($this->mode == 'create') {
                    $this->repeatCreateAction = $entityData['repeatCreation'];
                }
                unset($entityData['repeatCreation']);
            }
            if (isset($entityData['additionalNotificationRemarks'])) {
                «IF app.isLegacy»
                    SessionUtil::setVar($this->name . 'AdditionalNotificationRemarks', $entityData['additionalNotificationRemarks']);
                «ELSE»
                    $this->request->getSession()->set($this->name . 'AdditionalNotificationRemarks', $entityData['additionalNotificationRemarks']);
                «ENDIF»
                unset($entityData['additionalNotificationRemarks']);
            }
            «IF hasAttributableEntities»

                if ($this->hasAttributes === true) {
                    $this->processAttributesForUpdate($entity, $formData);
                }
            «ENDIF»

            «IF app.isLegacy»
                «legacyParts.processExtensions(it)»

            «ENDIF»
            // assign fetched data
            $entity->merge($entityData);
            «IF app.isLegacy»

                // we must persist related items now (after the merge) to avoid validation errors
                // if cascades cause the main entity becoming persisted automatically, too
                $this->persistRelationData($view);
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

    def private applyAction(Application it, String actionName) '''
        /**
         * This method executes a certain workflow action.
         *
         * @param Array $args Arguments from handleCommand method.
         *
         * @return bool Whether everything worked well or not.
         */
        public function applyAction(array $args = «IF isLegacy»array()«ELSE»[]«ENDIF»)
        {
            // stub for subclasses
            return false;
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
         *
         * More documentation is provided in the parent class.
         */
        «IF app.isLegacy»
        class «app.appName»_Form_Handler_«name.formatForCodeCapital»_Base_«actionName.formatForCodeCapital» extends «app.appName»_Form_Handler_Common_«actionName.formatForCodeCapital»
        «ELSE»
        class «actionName.formatForCodeCapital»Handler extends Base«actionName.formatForCodeCapital»Handler
        «ENDIF»
        {
            «formHandlerBasePreInitialize»

            «initialize(actionName)»

            «IF ownerPermission && standardFields»

                «formHandlerBaseInitEntityForEditing»
            «ENDIF»

            «redirectHelper.getRedirectCodes(it, app, actionName)»

            «redirectHelper.getDefaultReturnUrl(it, app, actionName)»

            «handleCommand(it, actionName)»

            «applyAction(it, actionName)»

            «redirectHelper.getRedirectUrl(it, app, actionName)»
        }
    '''

    def private formHandlerBaseImports(Entity it, String actionName) '''
        «val app = application»
        «IF !app.isLegacy»
            namespace «app.appNamespace»\Form\Handler\«name.formatForCodeCapital»\Base;

            use «app.appNamespace»\Form\Handler\Common\«actionName.formatForCodeCapital»Handler as Base«actionName.formatForCodeCapital»Handler;

        «ENDIF»
        «IF hasOptimisticLock || hasPessimisticReadLock || hasPessimisticWriteLock»
            use Doctrine\DBAL\LockMode;
            «IF hasOptimisticLock»
                use Doctrine\ORM\OptimisticLockException;
            «ENDIF»
        «ENDIF»
        «IF !app.isLegacy»

            use Symfony\Component\Security\Core\Exception\AccessDeniedException;

            use FormUtil;
            use ModUtil;
            use SecurityUtil;
            use System;
            use UserUtil;
        «ENDIF»
    '''

    def private formHandlerBasePreInitialize(Entity it) '''
        /**
         * Pre-initialise hook.
         *
         * @return void
         */
        public function preInitialize()
        {
            parent::preInitialize();

            $this->objectType = '«name.formatForCode»';
            $this->objectTypeCapital = '«name.formatForCodeCapital»';
            $this->objectTypeLower = '«name.formatForDB»';

            $this->hasPageLockSupport = «hasPageLockSupport.displayBool»;
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
            «IF app.isLegacy»
                «legacyParts.setMemberVars(it)»
            «ENDIF»
        }
    '''

    def private formHandlerBaseInitEntityForEditing(Entity it) '''
        /**
         * Initialise existing entity for editing.
         *
         * @return Zikula_EntityAccess desired entity instance or null
         */
        protected function initEntityForEditing()
        {
            $entity = parent::initEntityForEditing();

            // only allow editing for the owner or people with higher permissions
            if (isset($entity['createdUserId']) && $entity['createdUserId'] != UserUtil::getVar('uid')) {
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


    def private initialize(Entity it, String actionName) '''
        /**
         * Initialize form handler.
         *
         * This method takes care of all necessary initialisation of our data and form states.
         *
         * @param Zikula_Form_View $view The form view instance.
         *
         * @return boolean False in case of initialization errors, otherwise true.
         */
        public function initialize(Zikula_Form_View $view)
        {
            $result = parent::initialize($view);
            if ($result === false) {
                return $result;
            }

            if ($this->mode == 'create') {
                «IF app.isLegacy»
                    $modelHelper = new «app.appName»_Util_Model($this->view->getServiceManager());
                «ELSE»
                    $modelHelper = $this->container->get('«app.appName.formatForDB».model_helper');
                «ENDIF»
                if (!$modelHelper->canBeCreated($this->objectType)) {
                    «IF app.isLegacy»
                        LogUtil::registerError($this->__('Sorry, but you can not create the «name.formatForDisplay» yet as other items are required which must be created before!'));
                    «ELSE»
                        $logger = $this->container->get('logger');
                        $logger->notice('{app}: User {user} tried to create a new {entity}, but failed as it other items are required which must be created before.', ['app' => '«app.appName»', 'user' => UserUtil::getVar('uname'), 'entity' => $this->objectType]);
                    «ENDIF»

                    return $this->view->redirect($this->getRedirectUrl(null));
                }
            }

            $entity = $this->entityRef;
            «IF hasOptimisticLock»

                if ($this->mode == 'edit') {
                    «IF app.isLegacy»
                        SessionUtil::setVar($this->name . 'EntityVersion', $entity->get«getVersionField.name.formatForCodeCapital»());
                    «ELSE»
                        $this->request->getSession()->set($this->name . 'EntityVersion', $entity->get«getVersionField.name.formatForCodeCapital»());
                    «ENDIF»
                }
            «ENDIF»
            «relationPresetsHelper.initPresets(it)»

            // save entity reference for later reuse
            $this->entityRef = $entity;

            $entityData = $entity->toArray();
            «IF app.isLegacy && app.hasListFields»

                if (count($this->listFields) > 0) {
                    «IF app.isLegacy»
                        $helper = new «app.appName»_Util_ListEntries($this->view->getServiceManager());
                    «ELSE»
                        $helper = $this->container->get('«app.appName.formatForDB».listentries_helper');
                    «ENDIF»

                    foreach ($this->listFields as $listField => $isMultiple) {
                        $entityData[$listField . 'Items'] = $helper->getEntries($this->objectType, $listField);
                        if ($isMultiple) {
                            $entityData[$listField] = $helper->extractMultiList($entityData[$listField]);
                        }
                    }
                }
            «ENDIF»

            // assign data to template as array (makes translatable support easier)
            $this->view->assign($this->objectTypeLower, $entityData);

            if ($this->mode == 'edit') {
                // assign formatted title
                $this->view->assign('formattedEntityTitle', $entity->getTitleFromDisplayPattern());
            }
            «IF workflow != EntityWorkflowType.NONE»

                $uid = UserUtil::getVar('uid');
                $isCreator = $entity['createdUserId'] == $uid;
                «IF !app.isLegacy»
                    $varHelper = $this->container->get('zikula_extensions_module.api.variable');
                «ENDIF»
                «IF workflow == EntityWorkflowType.ENTERPRISE»
                    $groupArgs = «IF app.isLegacy»array(«ELSE»[«ENDIF»'uid' => $uid, 'gid' => «IF app.isLegacy»$this->getVar(«ELSE»$varHelper->get('«app.appName»', «ENDIF»'moderationGroupFor' . $this->objectTypeCapital, 2)«IF app.isLegacy»)«ELSE»]«ENDIF»;
                    $isModerator = ModUtil::apiFunc('«IF app.isLegacy»Groups«ELSE»ZikulaGroupsModule«ENDIF»', 'user', 'isgroupmember', $groupArgs);
                    $groupArgs = «IF app.isLegacy»array(«ELSE»[«ENDIF»'uid' => $uid, 'gid' => «IF app.isLegacy»$this->getVar(«ELSE»$varHelper->get('«app.appName»', «ENDIF»'superModerationGroupFor' . $this->objectTypeCapital, 2)«IF app.isLegacy»)«ELSE»]«ENDIF»;
                    $isSuperModerator = ModUtil::apiFunc('«IF app.isLegacy»Groups«ELSE»ZikulaGroupsModule«ENDIF»', 'user', 'isgroupmember', $groupArgs);

                    $this->view->assign('isCreator', $isCreator)
                               ->assign('isModerator', $isModerator)
                               ->assign('isSuperModerator', $isSuperModerator);
                «ELSEIF workflow == EntityWorkflowType.STANDARD»
                    $groupArgs = «IF app.isLegacy»array(«ELSE»[«ENDIF»'uid' => $uid, 'gid' => «IF app.isLegacy»$this->getVar(«ELSE»$varHelper->get('«app.appName»', «ENDIF»'moderationGroupFor' . $this->objectTypeCapital, 2)«IF app.isLegacy»)«ELSE»]«ENDIF»;
                    $isModerator = ModUtil::apiFunc('«IF app.isLegacy»Groups«ELSE»ZikulaGroupsModule«ENDIF»', 'user', 'isgroupmember', $groupArgs);

                    $this->view->assign('isCreator', $isCreator)
                               ->assign('isModerator', $isModerator)
                               ->assign('isSuperModerator', false);
                «ENDIF»
            «ENDIF»

            // everything okay, no initialization errors occured
            return true;
        }
    '''

    def private handleCommand(Entity it, String actionName) '''
        /**
         * Command event handler.
         *
         * This event handler is called when a command is issued by the user.
         *
         * @param Zikula_Form_View $view The form view instance.
         * @param array            $args Additional arguments.
         *
         * @return mixed Redirect or false on errors.
         */
        public function handleCommand(Zikula_Form_View $view, &$args)
        {
            $result = parent::handleCommand($view, $args);
            if ($result === false) {
                return $result;
            }

            return $this->view->redirect($this->getRedirectUrl($args));
        }

        /**
         * Get success or error message for default operations.
         *
         * @param Array   $args    Arguments from handleCommand method.
         * @param Boolean $success Becomes true if this is a success, false for default error.
         *
         * @return String desired status or error message.
         */
        protected function getDefaultMessage($args, $success = false)
        {
            if ($success !== true) {
                return parent::getDefaultMessage($args, $success);
            }

            $message = '';
            switch ($args['commandName']) {
                «IF app.hasWorkflowState('deferred')»
                 case 'defer':
                «ENDIF»
                case 'submit':
                            if ($this->mode == 'create') {
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

    def private applyAction(Entity it, String actionName) '''
        /**
         * This method executes a certain workflow action.
         *
         * @param Array $args Arguments from handleCommand method.
         *
         * @return bool Whether everything worked well or not.
         «IF !app.isLegacy»
         *
         * @throws RuntimeException Thrown if concurrent editing is recognised or another error occurs
         «ENDIF»
         */
        public function applyAction(array $args = «IF app.isLegacy»array()«ELSE»[]«ENDIF»)
        {
            // get treated entity reference from persisted member var
            $entity = $this->entityRef;

            if (!$entity->validate()) {
                return false;
            }

            $action = $args['commandName'];
            «IF hasOptimisticLock || hasPessimisticWriteLock»

                $applyLock = ($this->mode != 'create' && $action != 'delete');
                «IF hasOptimisticLock»
                    «IF app.isLegacy»
                        $expectedVersion = SessionUtil::getVar($this->name . 'EntityVersion', 1);
                    «ELSE»
                        $expectedVersion = $this->request->getSession()->get($this->name . 'EntityVersion', 1);
                    «ENDIF»
                «ENDIF»
            «ENDIF»

            $success = false;
            try {
                «IF hasOptimisticLock || hasPessimisticWriteLock»
                    if ($applyLock) {
                        // assert version
                        «IF hasOptimisticLock»
                            $this->entityManager->lock($entity, LockMode::OPTIMISTIC, $expectedVersion);
                        «ELSEIF hasPessimisticWriteLock»
                            $this->entityManager->lock($entity, LockMode::«lockType.lockTypeAsConstant»);
                        «ENDIF»
                    }

                «ENDIF»
                // execute the workflow action
                «IF app.isLegacy»
                    $workflowHelper = new «app.appName»_Util_Workflow($this->view->getServiceManager());
                «ELSE»
                    $workflowHelper = $this->container->get('«app.appName.formatForDB».workflow_helper');
                    $flashBag = $this->request->getSession()->getFlashBag();
                    $logger = $this->container->get('logger');
                «ENDIF»
                $success = $workflowHelper->executeAction($entity, $action);
            «IF hasOptimisticLock»
                } catch(OptimisticLockException $e) {
                    «IF app.isLegacy»
                        LogUtil::registerError($this->__('Sorry, but someone else has already changed this record. Please apply the changes again!'));
                    «ELSE»
                        $flashBag->add(\Zikula_Session::MESSAGE_ERROR, $this->__('Sorry, but someone else has already changed this record. Please apply the changes again!'));
                        $logger->error('{app}: User {user} tried to edit the {entity} with id {id}, but failed as someone else has already changed it.', ['app' => '«app.appName»', 'user' => UserUtil::getVar('uname'), 'entity' => '«name.formatForDisplay»', 'id' => $entity->createCompositeIdentifier()]);
                    «ENDIF»
            «ENDIF»
            } catch(\Exception $e) {
                «IF app.isLegacy»
                    LogUtil::registerError($this->__f('Sorry, but an unknown error occured during the %s action. Please apply the changes again!', array($action)));
                «ELSE»
                    $flashBag->add(\Zikula_Session::MESSAGE_ERROR, $this->__f('Sorry, but an unknown error occured during the %s action. Please apply the changes again!', [$action]));
                    $logger->error('{app}: User {user} tried to edit the {entity} with id {id}, but failed. Error details: {errorMessage}.', ['app' => '«app.appName»', 'user' => UserUtil::getVar('uname'), 'entity' => '«name.formatForDisplay»', 'id' => $entity->createCompositeIdentifier(), 'errorMessage' => $e->getMessage()]);
                «ENDIF»
            }

            $this->addDefaultMessage($args, $success);

            if ($success && $this->mode == 'create') {
                // store new identifier
                foreach ($this->idFields as $idField) {
                    $this->idValues[$idField] = $entity[$idField];
                }
            }

            «relationPresetsHelper.saveNonEditablePresets(it, app)»

            return $success;
        }
    '''

    def private isLegacy(Application it) {
        targets('1.3.x')
    }
}
