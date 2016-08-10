package org.zikula.modulestudio.generator.cartridges.zclassic.controller

import de.guite.modulestudio.metamodel.Action
import de.guite.modulestudio.metamodel.AdminController
import de.guite.modulestudio.metamodel.AjaxController
import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.Controller
import de.guite.modulestudio.metamodel.DisplayAction
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.EntityTreeType
import de.guite.modulestudio.metamodel.NamedObject
import de.guite.modulestudio.metamodel.UserController
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions.Ajax
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions.ExternalController
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions.Routing
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions.Scribite
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions.UrlRoutingLegacy
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.apis.ShortUrlsLegacy
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.QuickNavigation
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.javascript.DisplayFunctions
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.javascript.EditFunctions
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.javascript.Finder
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.javascript.TreeFunctions
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.javascript.Validation
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.CollectionUtils
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelJoinExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ControllerLayer {

    extension CollectionUtils = new CollectionUtils
    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelJoinExtensions = new ModelJoinExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    FileHelper fh = new FileHelper
    Application app
    ControllerAction actionHelper

    /**
     * Entry point for the controller creation.
     */
    def void generate(Application it, IFileSystemAccess fsa) {
        this.app = it
        this.actionHelper = new ControllerAction(app)

        // controllers and apis
        controllers.forEach[generateControllerAndApi(fsa)]
        getAllEntities.forEach[generateController(fsa)]

        if (isLegacy) {
            if (hasUserController) {
                new UrlRoutingLegacy().generate(it, fsa)
            }
        } else {
            new Routing().generate(it, fsa)
            if (hasViewActions) {
                new QuickNavigation().generate(it, fsa)
            }
        }

        if (generateExternalControllerAndFinder) {
            // controller for external calls
            new ExternalController().generate(it, fsa)

            if (generateScribitePlugins) {
                // Scribite integration
                new Scribite().generate(it, fsa)
            }
        }

        // JavaScript
        if (generateExternalControllerAndFinder) {
            new Finder().generate(it, fsa)
        }
        if (hasEditActions) {
            new EditFunctions().generate(it, fsa)
        }
        new DisplayFunctions().generate(it, fsa)
        if (hasTrees) {
            new TreeFunctions().generate(it, fsa)
        }
        new Validation().generate(it, fsa)
    }

    /**
     * Creates controller and api class files for every Controller instance.
     */
    def private generateControllerAndApi(Controller it, IFileSystemAccess fsa) {
        println('Generating "' + formattedName + '" controller classes')
        app.generateClassPair(fsa, app.getAppSourceLibPath + 'Controller/' + name.formatForCodeCapital + (if (isLegacy) '' else 'Controller') + '.php',
            fh.phpFileContent(app, controllerBaseImpl), fh.phpFileContent(app, controllerImpl)
        )

        if (isLegacy) {
            println('Generating "' + formattedName + '" api classes')
            app.generateClassPair(fsa, app.getAppSourceLibPath + 'Api/' + name.formatForCodeCapital + '.php',
                fh.phpFileContent(app, apiBaseImpl), fh.phpFileContent(app, apiImpl)
            )
        } else {
            println('Generating link container class')
            app.generateClassPair(fsa, app.getAppSourceLibPath + 'Container/LinkContainer.php',
                fh.phpFileContent(app, linkContainerBaseImpl), fh.phpFileContent(app, linkContainerImpl)
            )
        }
    }

    /**
     * Creates controller class files for every Entity instance.
     */
    def private generateController(Entity it, IFileSystemAccess fsa) {
        println('Generating "' + name.formatForDisplay + '" controller classes')
        app.generateClassPair(fsa, app.getAppSourceLibPath + 'Controller/' + name.formatForCodeCapital + (if (isLegacy) '' else 'Controller') + '.php',
            fh.phpFileContent(app, entityControllerBaseImpl), fh.phpFileContent(app, entityControllerImpl)
        )
    }

    def private controllerBaseImpl(Controller it) '''
        «val isAjaxController = (it instanceof AjaxController)»
        «controllerBaseImports»
        /**
         * «name» controller class.
         */
        class «IF isLegacy»«app.appName»_Controller_Base_«name.formatForCodeCapital» extends Zikula_«IF !isAjaxController»AbstractController«ELSE»Controller_AbstractAjax«ENDIF»«ELSE»«name.formatForCodeCapital»Controller extends AbstractController«ENDIF»
        {
            «IF isAjaxController»

            «ELSEIF isLegacy»
                «val isUserController = (it instanceof UserController)»
                «new ControllerHelperFunctions().controllerPostInitialize(it, isUserController, '')»
            «ENDIF»

            «FOR action : actions»
                «actionHelper.generate(action, true)»

            «ENDFOR»
            «IF hasActions('edit') && app.needsAutoCompletion»

                «handleInlineRedirect(true)»
            «ENDIF»
            «IF app.needsConfig && isConfigController»

                «configAction(true)»
            «ENDIF»
            «IF isAjaxController»
                «new Ajax().additionalAjaxFunctionsBase(it, app)»
            «ENDIF»
        }
    '''

    def private entityControllerBaseImpl(Entity it) '''
        «entityControllerBaseImports»
        /**
         * «name.formatForDisplayCapital» controller base class.
         */
        class «IF isLegacy»«app.appName»_Controller_Base_«name.formatForCodeCapital» extends Zikula_AbstractController«ELSE»«name.formatForCodeCapital»Controller extends AbstractController«ENDIF»
        {
            «IF isLegacy»
                «new ControllerHelperFunctions().controllerPostInitialize(it, false, '')»

            «ENDIF»
            «FOR action : actions»
                «adminAndUserImpl(action, true)»
            «ENDFOR»
            «IF hasActions('view')»

                «handleSelectedObjects(true, true)»
                «handleSelectedObjects(true, false)»
            «ENDIF»
            «IF hasActions('edit') && app.needsAutoCompletion»

                «handleInlineRedirect(true)»
            «ENDIF»
        }
    '''

    def private controllerBaseImports(Controller it) '''
        «val isAdminController = (it instanceof AdminController)»
        «val isAjaxController = (it instanceof AjaxController)»
        «IF !isLegacy»
            namespace «app.appNamespace»\Controller\Base;

            use Symfony\Component\HttpFoundation\Request;
            use Symfony\Component\Security\Core\Exception\AccessDeniedException;
            «IF hasActions('display') || hasActions('edit') || hasActions('delete')»
                use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
            «ENDIF»
            «IF hasActions('index') || hasActions('view') || hasActions('delete') || (app.needsConfig && isConfigController)»
                use Symfony\Component\HttpFoundation\RedirectResponse;
            «ENDIF»
            «IF isAjaxController»
                «IF !app.getAllUserFields.empty»
                    use Doctrine\ORM\AbstractQuery;
                «ENDIF»
                use DataUtil;
            «ENDIF»
            «IF hasActions('edit') && app.needsAutoCompletion»
                use JCSSUtil;
            «ENDIF»
            use ModUtil;
            use RuntimeException;
            «IF (hasActions('view') && isAdminController) || hasActions('index') || hasActions('delete')»
                use System;
            «ENDIF»
            use ZLanguage;
            use Zikula\Core\Controller\AbstractController;
            use Zikula\Core\RouteUrl;
            «controllerBaseImportsResponse»

        «ENDIF»
    '''

    def private entityControllerBaseImports(Entity it) '''
        «IF !isLegacy»
            namespace «app.appNamespace»\Controller\Base;

            use «entityClassName('', false)»;
            use Symfony\Component\HttpFoundation\Request;
            use Symfony\Component\Security\Core\Exception\AccessDeniedException;
            «IF hasActions('display') || hasActions('edit') || hasActions('delete')»
                use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
            «ENDIF»
            «IF hasActions('index') || hasActions('view') || hasActions('delete')»
                use Symfony\Component\HttpFoundation\RedirectResponse;
            «ENDIF»
            use Sensio\Bundle\FrameworkExtraBundle\Configuration\Cache;
            «IF hasActions('display') || hasActions('delete')»
                use Sensio\Bundle\FrameworkExtraBundle\Configuration\ParamConverter;
            «ENDIF»
            use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
            use FormUtil;
            «IF hasActions('edit') && app.needsAutoCompletion»
                use JCSSUtil;
            «ENDIF»
            use ModUtil;
            use RuntimeException;
            «IF (hasActions('view') && app.hasAdminController) || hasActions('index') || hasActions('delete')»
                use System;
            «ENDIF»
            use ZLanguage;
            «IF hasActions('view')»
                use Zikula\Component\SortableColumns\Column;
                use Zikula\Component\SortableColumns\SortableColumns;
            «ENDIF»
            use Zikula\Core\Controller\AbstractController;
            use Zikula\Core\ModUrl;
            use Zikula\Core\RouteUrl;
            «entityControllerBaseImportsResponse»
            use Zikula\ThemeModule\Engine\Annotation\Theme;

        «ENDIF»
    '''

    def private controllerBaseImportsResponse(Controller it) '''
        «IF it instanceof AjaxController»
            use Zikula\Core\Response\Ajax\AjaxResponse;
            use Zikula\Core\Response\Ajax\BadDataResponse;
            use Zikula\Core\Response\Ajax\FatalResponse;
            use Zikula\Core\Response\Ajax\NotFoundResponse;
            use Symfony\Component\HttpFoundation\JsonResponse;
        «ENDIF»
        use Zikula\Core\Response\PlainResponse;
    '''

    def private entityControllerBaseImportsResponse(Entity it) '''
        use Zikula\Core\Response\PlainResponse;
    '''

    def private handleSelectedObjects(Entity it, Boolean isBase, Boolean isAdmin) '''
        «handleSelectedObjectsDocBlock(isBase)»
        public function «IF isAdmin»adminH«ELSE»h«ENDIF»andleSelectedEntries«IF isLegacy»()«ELSE»Action(Request $request)«ENDIF»
        {
            «IF isBase»
                «IF isLegacy»
                    «handleSelectedObjectsBaseImpl»
                «ELSE»
                    return $this->handleSelectedEntriesActionInternal($request, «isAdmin.displayBool»);
                «ENDIF»
            «ELSE»
                return parent::«IF isAdmin»adminH«ELSE»h«ENDIF»andleSelectedEntriesAction($request);
            «ENDIF»
        }
        «IF !isLegacy && isBase && !isAdmin»

            /**
             * This method includes the common implementation code for adminHandleSelectedEntriesAction() and handleSelectedEntriesAction().
             */
            protected function handleSelectedEntriesActionInternal(Request $request, $isAdmin = false)
            {
                «handleSelectedObjectsBaseImpl»
            }
        «ENDIF»
    '''

    def private handleSelectedObjectsDocBlock(Entity it, Boolean isBase) '''
        /**
         * Process status changes for multiple items.
         *
         * This function processes the items selected in the admin view page.
         * Multiple items may have their state changed or be deleted.
         «IF !isLegacy && !isBase»
         *
         * @Route("/«nameMultiple.formatForCode»/handleSelectedEntries",
         *        methods = {"POST"}
         * )
         «ENDIF»
         *
         * @param Request $request Current request instance
         *
         * @return bool true on sucess, false on failure
         «IF !isLegacy»
         *
         * @throws RuntimeException Thrown if executing the workflow action fails
         «ENDIF»
         */
    '''

    def private handleSelectedObjectsBaseImpl(Entity it) '''
        «IF isLegacy»
            $this->checkCsrfToken();

        «ENDIF»
        $objectType = '«name.formatForCode»';

        // Get parameters
        $action = $«IF isLegacy»this->«ENDIF»request->request->get('action', null);
        $items = $«IF isLegacy»this->«ENDIF»request->request->get('items', null);

        $action = strtolower($action);

        «IF isLegacy»
            $workflowHelper = new «app.appName»_Util_Workflow($this->serviceManager);
            «IF !skipHookSubscribers»
                $hookHelper = new «app.appName»_Util_Hook($this->serviceManager);
            «ENDIF»
        «ELSE»
            $workflowHelper = $this->get('«app.appService».workflow_helper');
            «IF !skipHookSubscribers»
                $hookHelper = $this->get('«app.appService».hook_helper');
            «ENDIF»
            $flashBag = $request->getSession()->getFlashBag();
            $logger = $this->get('logger');
            $userName = $this->get('zikula_users_module.current_user')->get('uname');
        «ENDIF»

        // process each item
        foreach ($items as $itemid) {
            // check if item exists, and get record instance
            $selectionArgs = «IF isLegacy»array(«ELSE»[«ENDIF»
                'ot' => $objectType,
                'id' => $itemid,
                'useJoins' => false
            «IF isLegacy»)«ELSE»]«ENDIF»;
            $entity = ModUtil::apiFunc($this->name, 'selection', 'getEntity', $selectionArgs);

            $entity->initWorkflow();

            // check if $action can be applied to this entity (may depend on it's current workflow state)
            $allowedActions = $workflowHelper->getActionsForObject($entity);
            $actionIds = array_keys($allowedActions);
            if (!in_array($action, $actionIds)) {
                // action not allowed, skip this object
                continue;
            }

            «IF !skipHookSubscribers»
                // Let any hooks perform additional validation actions
                $hookType = $action == 'delete' ? 'validate_delete' : 'validate_edit';
                $validationHooksPassed = $hookHelper->callValidationHooks($entity, $hookType);
                if (!$validationHooksPassed) {
                    continue;
                }

            «ENDIF»
            $success = false;
            try {
                if (!$entity->validate()) {
                    continue;
                }
                // execute the workflow action
                $success = $workflowHelper->executeAction($entity, $action);
            } catch(\Exception $e) {
                «IF isLegacy»
                    LogUtil::registerError($this->__f('Sorry, but an unknown error occured during the %s action. Please apply the changes again!', array($action)));
                «ELSE»
                    $flashBag->add(\Zikula_Session::MESSAGE_ERROR, $this->__f('Sorry, but an unknown error occured during the %s action. Please apply the changes again!', [$action]));
                    $logger->error('{app}: User {user} tried to execute the {action} workflow action for the {entity} with id {id}, but failed. Error details: {errorMessage}.', ['app' => '«app.appName»', 'user' => $userName, 'action' => $action, 'entity' => '«name.formatForDisplay»', 'id' => $itemid, 'errorMessage' => $e->getMessage()]);
                «ENDIF»
            }

            if (!$success) {
                continue;
            }

            if ($action == 'delete') {
                «IF isLegacy»
                    LogUtil::registerStatus($this->__('Done! Item deleted.'));
                «ELSE»
                    $flashBag->add(\Zikula_Session::MESSAGE_STATUS, $this->__('Done! Item deleted.'));
                    $logger->notice('{app}: User {user} deleted the {entity} with id {id}.', ['app' => '«app.appName»', 'user' => $userName, 'entity' => '«name.formatForDisplay»', 'id' => $itemid]);
                «ENDIF»
            } else {
                «IF isLegacy»
                    LogUtil::registerStatus($this->__('Done! Item updated.'));
                «ELSE»
                    $flashBag->add(\Zikula_Session::MESSAGE_STATUS, $this->__('Done! Item updated.'));
                    $logger->notice('{app}: User {user} executed the {action} workflow action for the {entity} with id {id}.', ['app' => '«app.appName»', 'user' => $userName, 'action' => $action, 'entity' => '«name.formatForDisplay»', 'id' => $itemid]);
                «ENDIF»
            }
            «IF !skipHookSubscribers»

                // Let any hooks know that we have updated or deleted an item
                $hookType = $action == 'delete' ? 'process_delete' : 'process_edit';
                $url = null;
                if ($action != 'delete') {
                    $urlArgs = $entity->createUrlArgs();
                    «IF isLegacy»
                        $url = new Zikula_ModUrl($this->name, '«name.formatForCode»', 'display', ZLanguage::getLanguageCode(), $urlArgs);
                    «ELSE»
                        $url = new RouteUrl('«app.appName.formatForDB»_«name.formatForCode»_' . /*($isAdmin ? 'admin' : '') . */'display', $urlArgs);
                    «ENDIF»
                }
                $hookHelper->callProcessHooks($entity, $hookType, $url);
            «ENDIF»
            «IF isLegacy»

                // An item was updated or deleted, so we clear all cached pages for this item.
                $cacheArgs = array('ot' => $objectType, 'item' => $entity);
                ModUtil::apiFunc($this->name, 'cache', 'clearItemCache', $cacheArgs);
            «ENDIF»
        }

        «IF isLegacy»
            // clear view cache to reflect our changes
            $this->view->clear_cache();

            $redirectUrl = ModUtil::url($this->name, 'admin', 'main', array('ot' => '«name.formatForCode»'));

            return $this->redirect($redirectUrl);
        «ELSE»
            return $this->redirectToRoute('«app.appName.formatForDB»_«name.formatForDB»_' . ($isAdmin ? 'admin' : '') . 'index');
        «ENDIF»
    '''

    def private handleInlineRedirect(NamedObject it, Boolean isBase) '''
        «handleInlineRedirectDocBlock(isBase)»
        public function handleInlineRedirect«IF isLegacy»()«ELSE»Action($idPrefix, $commandName, $id = 0)«ENDIF»
        {
            «IF isBase»
                «handleInlineRedirectBaseImpl»
            «ELSE»
                return parent::handleInlineRedirectAction($idPrefix, $commandName, $id);
            «ENDIF»
        }
    '''

    def private handleInlineRedirectDocBlock(NamedObject it, Boolean isBase) '''
        /**
         * This method cares for a redirect within an inline frame.
         «IF it instanceof Entity && !isLegacy && !isBase»
         *
         * @Route("/«name.formatForCode»/handleInlineRedirect/{idPrefix}/{commandName}/{id}",
         *        requirements = {"id" = "\d+"},
         *        defaults = {"commandName" = "", "id" = 0},
         *        methods = {"GET"}
         * )
         «ENDIF»
         *
         * @param string  $idPrefix    Prefix for inline window element identifier
         * @param string  $commandName Name of action to be performed (create or edit)
         * @param integer $id          Id of created item (used for activating auto completion after closing the modal window)
         *
         * @return boolean Whether the inline redirect has been performed or not
         */
    '''

    def private handleInlineRedirectBaseImpl(NamedObject it) '''
        «IF isLegacy || it instanceof Controller»
            $id = (int) $this->request->query->filter('id', 0, FILTER_VALIDATE_INT);
            $idPrefix = $this->request->query->filter('idPrefix', '', FILTER_SANITIZE_STRING);
            $commandName = $this->request->query->filter('commandName', '', FILTER_SANITIZE_STRING);
        «ENDIF»
        if (empty($idPrefix)) {
            return false;
        }

        «IF isLegacy»
            $this->view->assign('itemId', $id)
                       ->assign('idPrefix', $idPrefix)
                       ->assign('commandName', $commandName)
                       ->assign('jcssConfig', JCSSUtil::getJSConfig());
        «ELSE»
            $templateParameters = [
                'itemId' => $id,
                'idPrefix' => $idPrefix,
                'commandName' => $commandName,
                'jcssConfig' => JCSSUtil::getJSConfig()
            ];
        «ENDIF»

        «val typeName = if (it instanceof Controller) it.formattedName else if (it instanceof Entity) it.name.formatForCode»
        «IF isLegacy»
            $this->view->display('«typeName»/inlineRedirectHandler.tpl');

            return true;
        «ELSE»
            return new PlainResponse($this->get('twig')->render('@«app.appName»/«typeName.toFirstUpper»/inlineRedirectHandler.html.twig', $templateParameters));
        «ENDIF»
    '''

    def private configAction(Controller it, Boolean isBase) '''
        «configDocBlock(isBase)»
        public function config«IF !isLegacy»Action«ENDIF»(«IF !isLegacy»Request $request«ENDIF»)
        {
            «IF isBase»
                «configBaseImpl»
            «ELSE»
                return parent::configAction(«IF !isLegacy»$request«ENDIF»);
            «ENDIF»
        }
    '''

    def private configDocBlock(Controller it, Boolean isBase) '''
        /**
         * This method takes care of the application configuration.
         «IF !isLegacy && !isBase»
         *
         * @Route("/config",
         *        methods = {"GET", "POST"}
         * )
         «ENDIF»
         «IF !isLegacy»
         *
         * @param Request $request Current request instance
         «ENDIF»
         *
         * @return string Output
         «IF !isLegacy»
         *
         * @throws AccessDeniedException Thrown if the user doesn't have required permissions
         «ENDIF»
         */
    '''

    def private configBaseImpl(Controller it) '''
        «IF isLegacy»
            $this->throwForbiddenUnless(SecurityUtil::checkPermission($this->name . '::', '::', ACCESS_ADMIN));
        «ELSE»
            if (!$this->hasPermission($this->name . '::', '::', ACCESS_ADMIN)) {
                throw new AccessDeniedException();
            }
        «ENDIF»

        «IF isLegacy»
            // Create new Form reference
            $view = \FormUtil::newForm($this->name, $this);

            $templateName = '«app.configController.formatForDB»/config.tpl';

            // Execute form using supplied template and page event handler
            return $view->execute($templateName, new «app.appName»_Form_Handler_«app.configController.formatForDB.toFirstUpper»_Config());
        «ELSE»
            $form = $this->createForm('«app.appNamespace»\Form\AppSettingsType');

            if ($form->handleRequest($request)->isValid()) {
                if ($form->get('save')->isClicked()) {
                    $this->setVars($form->getData());

                    $this->addFlash(\Zikula_Session::MESSAGE_STATUS, $this->__('Done! Module configuration updated.'));
                    $userName = $this->get('zikula_users_module.current_user')->get('uname');
                    $this->get('logger')->notice('{app}: User {user} updated the configuration.', ['app' => '«app.appName»', 'user' => $userName]);
                } elseif ($form->get('cancel')->isClicked()) {
                    $this->addFlash(\Zikula_Session::MESSAGE_STATUS, $this->__('Operation cancelled.'));
                }

                // redirect to config page again (to show with GET request)
                return $this->redirectToRoute('«app.appName.formatForDB»_«app.configController.formatForDB»_config');
            }

            $templateParameters = [
                'form' => $form->createView()
            ];

            // render the config form
            return $this->render('@«app.appName»/«app.configController.formatForCodeCapital»/config.html.twig', $templateParameters);
        «ENDIF»
    '''

    def private controllerImpl(Controller it) '''
        «IF !isLegacy»
            namespace «app.appNamespace»\Controller;

            use «app.appNamespace»\Controller\Base\«name.formatForCodeCapital»Controller as Base«name.formatForCodeCapital»Controller;

            «IF it instanceof AjaxController»
                use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
            «ENDIF»
            use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
            use Symfony\Component\HttpFoundation\Request;

        «ENDIF»
        /**
         * «name» controller class providing navigation and interaction functionality.
        «IF !isLegacy && it instanceof AjaxController»
         «' '»*
         «' '»* @Route("/ajax")
        «ENDIF»
         */
        «IF isLegacy»
        class «app.appName»_Controller_«name.formatForCodeCapital» extends «app.appName»_Controller_Base_«name.formatForCodeCapital»
        «ELSE»
        class «name.formatForCodeCapital»Controller extends Base«name.formatForCodeCapital»Controller
        «ENDIF»
        {
            «IF !isLegacy»
                «FOR action : actions»
                    «actionHelper.generate(action, false)»

                «ENDFOR»
                «IF hasActions('edit') && app.needsAutoCompletion»

                    «handleInlineRedirect(false)»
                «ENDIF»
                «IF app.needsConfig && isConfigController»

                    «configAction(false)»
                «ENDIF»
                «IF it instanceof AjaxController»
                    «new Ajax().additionalAjaxFunctions(it, app)»
                «ENDIF»
            «ENDIF»
            // feel free to add your own controller methods here
        }
    '''

    def private entityControllerImpl(Entity it) '''
        «IF !isLegacy»
            namespace «app.appNamespace»\Controller;

            use «app.appNamespace»\Controller\Base\«name.formatForCodeCapital»Controller as Base«name.formatForCodeCapital»Controller;

            use RuntimeException;
            use Symfony\Component\HttpFoundation\Request;
            use Symfony\Component\Security\Core\Exception\AccessDeniedException;
            «IF hasActions('display') || hasActions('edit') || hasActions('delete')»
                use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
            «ENDIF»
            use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
            use «app.appNamespace»\Entity\«name.formatForCodeCapital»Entity;

        «ENDIF»
        /**
         * «name.formatForDisplayCapital» controller class providing navigation and interaction functionality.
         */
        «IF isLegacy»
        class «app.appName»_Controller_«name.formatForCodeCapital» extends «app.appName»_Controller_Base_«name.formatForCodeCapital»
        «ELSE»
        class «name.formatForCodeCapital»Controller extends Base«name.formatForCodeCapital»Controller
        «ENDIF»
        {
            «IF !isLegacy»
                «IF hasSluggableFields»«/* put display method at the end to avoid conflict between delete/edit and display for slugs */»
                    «FOR action : actions.exclude(DisplayAction)»
                        «adminAndUserImpl(action as Action, false)»
                    «ENDFOR»
                    «FOR action : actions.filter(DisplayAction)»
                        «adminAndUserImpl(action, false)»
                    «ENDFOR»
                «ELSE»
                    «FOR action : actions»
                        «adminAndUserImpl(action, false)»
                    «ENDFOR»
                «ENDIF»
                «IF hasActions('view') && app.hasAdminController»

                    «handleSelectedObjects(false, true)»
                    «handleSelectedObjects(false, false)»
                «ENDIF»
                «IF hasActions('edit') && app.needsAutoCompletion»

                    «handleInlineRedirect(false)»
                «ENDIF»

            «ENDIF»
            // feel free to add your own controller methods here
        }
    '''

    def private adminAndUserImpl(Entity it, Action action, Boolean isBase) '''
        «IF !isLegacy»
            «actionHelper.generate(it, action, isBase, true)»

        «ENDIF»
        «actionHelper.generate(it, action, isBase, false)»
    '''

    // 1.3.x only
    def private apiBaseImpl(Controller it) '''
        «val isAjaxController = (it instanceof AjaxController)»
        /**
         * This is the «name» api helper class.
         */
        class «app.appName»_Api_Base_«name.formatForCodeCapital» extends Zikula_AbstractApi
        {
            «IF !isAjaxController»
            /**
             * Returns available «name.formatForDB» panel links.
             *
             * @return array Array of «name.formatForDB» links
             */
            public function getLinks()
            {
                $links = array();

                $controllerHelper = new «app.appName»_Util_Controller($this->serviceManager);
                $utilArgs = array('api' => '«it.formattedName»', 'action' => 'getLinks');
                $allowedObjectTypes = $controllerHelper->getObjectTypes('api', $utilArgs);

                $currentType = $this->request->query->filter('type', '«app.getLeadingEntity.name.formatForCode»', FILTER_SANITIZE_STRING);
                $currentLegacyType = $this->request->query->filter('lct', 'user', FILTER_SANITIZE_STRING);
                $permLevel = in_array('admin', array($currentType, $currentLegacyType)) ? ACCESS_ADMIN : ACCESS_READ;

                «getLinksBody»

                return $links;
            }
            «ENDIF»
            «additionalApiMethods»
        }
    '''

    // 1.4+ only
    def private linkContainerBaseImpl(Controller it) '''
        namespace «app.appNamespace»\Container\Base;

        use Symfony\Component\Routing\RouterInterface;
        «IF app.generateAccountApi»
            use UserUtil;
        «ENDIF»
        use Zikula\Common\Translator\TranslatorInterface;
        use Zikula\Common\Translator\TranslatorTrait;
        use Zikula\Core\LinkContainer\LinkContainerInterface;
        use Zikula\PermissionsModule\Api\PermissionApi;
        use «app.appNamespace»\Helper\ControllerHelper;

        /**
         * This is the link container service implementation class.
         */
        class LinkContainer implements LinkContainerInterface
        {
            use TranslatorTrait;

            /**
             * @var RouterInterface
             */
            protected $router;

            /**
             * @var PermissionApi
             */
            protected $permissionApi;

            /**
             * @var ControllerHelper
             */
            protected $controllerHelper;

            /**
             * Constructor.
             * Initialises member vars.
             *
             * @param TranslatorInterface $translator       Translator service instance
             * @param Routerinterface     $router           Router service instance
             * @param PermissionApi       $permissionApi    PermissionApi service instance
             * @param ControllerHelper    $controllerHelper ControllerHelper service instance
             */
            public function __construct(TranslatorInterface $translator, RouterInterface $router, PermissionApi $permissionApi, ControllerHelper $controllerHelper)
            {
                $this->setTranslator($translator);
                $this->router = $router;
                $this->permissionApi = $permissionApi;
                $this->controllerHelper = $controllerHelper;
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

            /**
             * Returns available header links.
             *
             * @param string $type The type to collect links for
             *
             * @return array Array of header links
             */
            public function getLinks($type = LinkContainerInterface::TYPE_ADMIN)
            {
                $utilArgs = ['api' => 'linkContainer', 'action' => 'getLinks'];
                $allowedObjectTypes = $this->controllerHelper->getObjectTypes('api', $utilArgs);
        
                $permLevel = LinkContainerInterface::TYPE_ADMIN == $type ? ACCESS_ADMIN : ACCESS_READ;

                // Create an array of links to return
                $links = [];

                «IF app.generateAccountApi»
                    if (LinkContainerInterface::TYPE_ACCOUNT == $type) {
                        $useAccountPage = $serviceManager->get('zikula_extensions_module.api.variable')->get('«app.appName»', 'useAccountPage', true);
                        if ($useAccountPage === false) {
                            return $links;
                        }

                        $userName = (isset($args['uname'])) ? $args['uname'] : $serviceManager->get('zikula_users_module.current_user')->get('uname');
                        // does this user exist?
                        if (UserUtil::getIdFromName($userName) === false) {
                            // user does not exist
                            return $links;
                        }

                        if (!$this->permissionApi->hasPermission($this->name . '::', '::', ACCESS_OVERVIEW)) {
                            return $links;
                        }

                        «IF !app.getAllUserControllers.empty && app.getMainUserController.hasActions('view')»
                            «FOR entity : app.getAllEntities.filter[standardFields && ownerPermission]»
                                $objectType = '«entity.name.formatForCode»';
                                if ($this->permissionApi->hasPermission($this->name . ':' . ucfirst($objectType) . ':', '::', ACCESS_READ)) {
                                    $links[] = [
                                        'url' => $this->router->generate('«app.appName.formatForDB»_' . strtolower($objectType) . '_view', ['own' => 1]),
                                        'text' => $this->__('My «entity.nameMultiple.formatForDisplay»'),
                                        'icon' => 'list-alt'
                                    ];
                                }
                            «ENDFOR»
                        «ENDIF»
                        «IF !app.getAllAdminControllers.empty»
                            if ($this->permissionApi->hasPermission($this->name . '::', '::', ACCESS_ADMIN)) {
                                $links[] = [
                                    'url' => $this->router->generate('«app.appName.formatForDB»_admin_index'),
                                    'text' => $this->__('«name.formatForDisplayCapital» Backend'),
                                    'icon' => 'wrench'
                                ];
                            }
                        «ENDIF»

                        return $links;
                    }

                «ENDIF»
                «/* TODO legacy, see #715 */»
                «var linkControllers = application.controllers.filter(AdminController) + application.controllers.filter(UserController)»
                «FOR linkController : linkControllers»
                    if («IF linkController instanceof AdminController»LinkContainerInterface::TYPE_ADMIN«ELSEIF linkController instanceof UserController»LinkContainerInterface::TYPE_USER«ELSE»'«linkController.name.formatForCode»'«ENDIF» == $type) {
                        «getLinksBody(linkController)»
                    }
                «ENDFOR»

                return $links;
            }

            public function getBundleName()
            {
                return '«app.appName»';
            }
        }
    '''

    def private getLinksBody(Controller it) '''
        «menuLinksBetweenControllers»

        «IF it instanceof AdminController || it instanceof UserController»
            «FOR entity : app.getAllEntities.filter[hasActions('view')]»
                «entity.menuLinkToViewAction(it)»
            «ENDFOR»
            «IF app.needsConfig && isConfigController»
                if («IF isLegacy»SecurityUtil::check«ELSE»$this->permissionApi->has«ENDIF»Permission(«IF isLegacy»$this->name«ELSE»$this->getBundleName()«ENDIF» . '::', '::', ACCESS_ADMIN)) {
                    «IF isLegacy»
                        $links[] = array(
                            'url' => ModUtil::url($this->name, '«app.configController.formatForDB»', 'config'),
                    «ELSE»
                        $links[] = [
                            'url' => $this->router->generate('«app.appName.formatForDB»_«app.configController.formatForDB»_config'),
                    «ENDIF»
                         'text' => $this->__('Configuration'),
                         'title' => $this->__('Manage settings for this application')«IF !isLegacy»,
                         'icon' => 'wrench'«ENDIF»
                     «IF isLegacy»)«ELSE»]«ENDIF»;
                }
            «ENDIF»
        «ENDIF»
    '''

    def private menuLinkToViewAction(Entity it, Controller controller) '''
        if (in_array('«name.formatForCode»', $allowedObjectTypes)
            && «IF isLegacy»SecurityUtil::check«ELSE»$this->permissionApi->has«ENDIF»Permission(«IF isLegacy»$this->name«ELSE»$this->getBundleName()«ENDIF» . ':«name.formatForCodeCapital»:', '::', $permLevel)) {
            «IF isLegacy»
                $links[] = array(
                    'url' => ModUtil::url($this->name, '«controller.formattedName»', 'view', array('ot' => '«name.formatForCode»'«IF tree != EntityTreeType.NONE», 'tpl' => 'tree'«ENDIF»)),
            «ELSE»
                $links[] = [
                    'url' => $this->router->generate('«app.appName.formatForDB»_«name.formatForDB»_«IF controller instanceof AdminController»admin«ENDIF»view'«IF tree != EntityTreeType.NONE», array('tpl' => 'tree')«ENDIF»),
            «ENDIF»
                 'text' => $this->__('«nameMultiple.formatForDisplayCapital»'),
                 'title' => $this->__('«name.formatForDisplayCapital» list')
             «IF isLegacy»)«ELSE»]«ENDIF»;
        }
    '''

    def private menuLinksBetweenControllers(Controller it) {
        switch it {
            AdminController case !application.getAllUserControllers.empty: '''
                    «val userController = application.getAllUserControllers.head»
                    if («IF isLegacy»SecurityUtil::check«ELSE»$this->permissionApi->has«ENDIF»Permission(«IF isLegacy»$this->name«ELSE»$this->getBundleName()«ENDIF» . '::', '::', ACCESS_READ)) {
                        «IF isLegacy»
                            $links[] = array(
                                'url' => ModUtil::url($this->name, '«userController.formattedName»', «userController.indexUrlDetails13»),
                        «ELSE»
                            $links[] = [
                                'url' => $this->router->generate('«app.appName.formatForDB»_«userController.formattedName»_«userController.indexUrlDetails14»),«/* end quote missing here on purpose */»
                        «ENDIF»
                             'text' => $this->__('Frontend'),
                             'title' => $this->__('Switch to user area.'),
                             «IF isLegacy»'class' => 'z-icon-es-home'«ELSE»'icon' => 'home'«ENDIF»
                         «IF isLegacy»)«ELSE»]«ENDIF»;
                    }
                    '''
            UserController case !application.getAllAdminControllers.empty: '''
                    «val adminController = application.getAllAdminControllers.head»
                    if («IF isLegacy»SecurityUtil::check«ELSE»$this->permissionApi->has«ENDIF»Permission(«IF isLegacy»$this->name«ELSE»$this->getBundleName()«ENDIF» . '::', '::', ACCESS_ADMIN)) {
                        «IF isLegacy»
                            $links[] = array(
                                'url' => ModUtil::url($this->name, '«adminController.formattedName»', «adminController.indexUrlDetails13»),
                        «ELSE»
                            $links[] = [
                                'url' => $this->router->generate('«app.appName.formatForDB»_«adminController.formattedName»_«adminController.indexUrlDetails14»),«/* end quote missing here on purpose */»
                        «ENDIF»
                             'text' => $this->__('Backend'),
                             'title' => $this->__('Switch to administration area.'),
                             «IF isLegacy»'class' => 'z-icon-es-options'«ELSE»'icon' => 'wrench'«ENDIF»
                         «IF isLegacy»)«ELSE»]«ENDIF»;
                    }
                    '''
        }
    }

    // 1.3.x only
    def private additionalApiMethods(Controller it) {
        switch it {
            UserController: if (isLegacy) new ShortUrlsLegacy(app).generate(it) else ''
            default: ''
        }
    }

    // 1.3.x only
    def private apiImpl(Controller it) '''
        /**
         * This is the «name» api helper class.
         */
        class «app.appName»_Api_«name.formatForCodeCapital» extends «app.appName»_Api_Base_«name.formatForCodeCapital»
        {
            // feel free to add own api methods here
        }
    '''

    // 1.4+ only
    def private linkContainerImpl(Controller it) '''
        namespace «app.appNamespace»\Container;

        use «app.appNamespace»\Container\Base\LinkContainer as BaseLinkContainer;

        /**
         * This is the link container service implementation class.
         */
        class LinkContainer extends BaseLinkContainer
        {
            // feel free to add own extensions here
        }
    '''

    def private indexUrlDetails14(Controller it) {
        if (hasActions('index')) 'index\''
        else if (hasActions('view')) 'view\', [\'ot\' => \'' + application.getLeadingEntity.name.formatForCode + '\']'
        else if (application.needsConfig && isConfigController) 'config\''
        else 'hooks\''
    }

    def private indexUrlDetails13(Controller it) {
        if (hasActions('index')) '\'main\''
        else if (hasActions('view')) '\'view\', array(\'ot\' => \'' + application.getLeadingEntity.name.formatForCode + '\')'
        else if (application.needsConfig && isConfigController) '\'config\''
        else '\'hooks\''
    }

    def private isLegacy() {
        app.targets('1.3.x')
    }
}