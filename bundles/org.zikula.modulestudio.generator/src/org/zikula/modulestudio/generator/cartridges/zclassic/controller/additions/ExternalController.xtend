package org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.ControllerHelperFunctions
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.Finder
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.cartridges.zclassic.view.additions.ExternalView
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ExternalController {
    extension FormattingExtensions = new FormattingExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    FileHelper fh = new FileHelper()

    def generate(Application it, IFileSystemAccess fsa) {
        println('Generating external controller')
        generateClassPair(fsa, getAppSourceLibPath + 'Controller/External' + (if (isLegacy) '' else 'Controller') + '.php',
            fh.phpFileContent(it, externalBaseClass), fh.phpFileContent(it, externalImpl)
        )
        new Finder().generate(it, fsa)
        new ExternalView().generate(it, fsa)
    }

    def private externalBaseClass(Application it) '''
    «IF !isLegacy»
        namespace «appNamespace»\Controller\Base;

        use Symfony\Component\Security\Core\Exception\AccessDeniedException;
        use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;

        «IF hasCategorisableEntities»
            use CategoryUtil;
        «ENDIF»
        use ModUtil;
        use PageUtil;
        use ThemeUtil;
        use UserUtil;
        use Zikula\Core\Controller\AbstractController;
        use Zikula\Core\Response\PlainResponse;
        «IF hasCategorisableEntities»
            use «appNamespace»\Helper\FeatureActivationHelper;
        «ENDIF»

    «ENDIF»
    /**
     * Controller for external calls base class.
     */
    abstract class «IF isLegacy»«appName»_Controller_Base_AbstractExternal extends Zikula_AbstractController«ELSE»AbstractExternalController extends AbstractController«ENDIF»
    {
        «IF hasCategorisableEntities»
            /**
             * List of object types allowing categorisation.
             *
             * @var array
             */
            protected $categorisableObjectTypes;

        «ENDIF»
        «IF isLegacy»
            «val additionalCommands = if (hasCategorisableEntities) categoryInitialisation else ''»
            «new ControllerHelperFunctions().controllerPostInitialize(it, false, additionalCommands.toString)»
        «ENDIF»

        «externalBaseImpl»
    }
    '''

    def private categoryInitialisation(Application it) '''
        $this->categorisableObjectTypes = «IF isLegacy»array(«ELSE»[«ENDIF»«FOR entity : getCategorisableEntities SEPARATOR ', '»'«entity.name.formatForCode»'«ENDFOR»«IF isLegacy»)«ELSE»]«ENDIF»;
    '''

    def private externalBaseImpl(Application it) '''
        «displayBase»

        «finderBase»
    '''

    def private displayBase(Application it) '''
        «displayDocBlock(true)»
        «displaySignature»
        {
            «displayBaseImpl»
        }
    '''

    def private displayDocBlock(Application it, Boolean isBase) '''
        /**
         * Displays one item of a certain object type using a separate template for external usages.
         «IF !isLegacy && !isBase»
         *
         * @Route("/display/{ot}/{id}/{source}/{displayMode}",
         *        requirements = {"id" = "\d+", "source" = "contentType|scribite", "displayMode" = "link|embed"},
         *        defaults = {"source" = "contentType", "contentType" = "embed"},
         *        methods = {"GET"}
         * )
         «ENDIF»
         *
         * @param string $ot          The currently treated object type
         * @param int    $id          Identifier of the entity to be shown
         * @param string $source      Source of this call (contentType or scribite)
         * @param string $displayMode Display mode (link or embed)
         *
         * @return string Desired data output
         */
    '''

    def private displaySignature(Application it) '''
        public function display«IF isLegacy»(array $args = array())«ELSE»Action($ot, $id, $source, $displayMode)«ENDIF»
    '''

    def private displayBaseImpl(Application it) '''
        «IF isLegacy»
            $getData = $this->request->query;
            $controllerHelper = new «appName»_Util_Controller($this->serviceManager);
        «ELSE»
            $controllerHelper = $this->get('«appService».controller_helper');
        «ENDIF»

        $objectType = «IF isLegacy»isset($args['objectType']) ? $args['objectType'] : $getData->filter('ot', '', FILTER_SANITIZE_STRING)«ELSE»$ot«ENDIF»;
        $utilArgs = «IF isLegacy»array(«ELSE»[«ENDIF»'controller' => 'external', 'action' => 'display'«IF isLegacy»)«ELSE»]«ENDIF»;
        if (!in_array($objectType, $controllerHelper->getObjectTypes('controller', $utilArgs))) {
            $objectType = $controllerHelper->getDefaultObjectType('controllerType', $utilArgs);
        }
        «IF isLegacy»

            $id = isset($args['id']) ? $args['id'] : $getData->filter('id', null, FILTER_SANITIZE_STRING);
        «ENDIF»

        $component = $this->name . ':' . ucfirst($objectType) . ':';
        if (!«IF isLegacy»SecurityUtil::check«ELSE»$this->has«ENDIF»Permission($component, $id . '::', ACCESS_READ)) {
            return '';
        }

        «IF isLegacy»
            $source = isset($args['source']) ? $args['source'] : $getData->filter('source', '', FILTER_SANITIZE_STRING);
            if (!in_array($source, array('contentType', 'scribite'))) {
                $source = 'contentType';
            }

            $displayMode = isset($args['displayMode']) ? $args['displayMode'] : $getData->filter('displayMode', 'embed', FILTER_SANITIZE_STRING);
            if (!in_array($displayMode, array('link', 'embed'))) {
                $displayMode = 'embed';
            }

            $entityClass = '«appName»_Entity_' . ucfirst($objectType);
            $repository = $this->entityManager->getRepository($entityClass);
            $repository->setControllerArguments(array());
            $idFields = ModUtil::apiFunc('«appName»', 'selection', 'getIdFields', array('ot' => $objectType));
        «ELSE»
            $repository = $this->get('«appService».' . $objectType . '_factory')->getRepository();
            $repository->setRequest($this->get('request_stack')->getCurrentRequest());
            $selectionHelper = $this->get('«appService».selection_helper');
            $idFields = $selectionHelper->getIdFields($objectType);
        «ENDIF»
        $idValues = «IF isLegacy»array(«ELSE»[«ENDIF»'id' => $id«IF isLegacy»)«ELSE»]«ENDIF»;«/** TODO consider composite keys properly */»

        $hasIdentifier = $controllerHelper->isValidIdentifier($idValues);
        if (!$hasIdentifier) {
            return $this->__('Error! Invalid identifier received.');
        }

        // assign object data fetched from the database
        $entity = $repository->selectById($idValues);
        if ((!is_array($entity) && !is_object($entity)) || !isset($entity[$idFields[0]])) {
            return $this->__('No such item.');
        }

        $entity->initWorkflow();

        $instance = $entity->createCompositeIdentifier() . '::';

        «IF isLegacy»
            $this->view->setCaching(Zikula_View::CACHE_ENABLED);

            // set cache id
            $accessLevel = ACCESS_READ;
            if («IF isLegacy»SecurityUtil::check«ELSE»$this->has«ENDIF»Permission($component, $instance, ACCESS_COMMENT)) {
                $accessLevel = ACCESS_COMMENT;
            }
            if («IF isLegacy»SecurityUtil::check«ELSE»$this->has«ENDIF»Permission($component, $instance, ACCESS_EDIT)) {
                $accessLevel = ACCESS_EDIT;
            }
            $this->view->setCacheId($objectType . '|' . $id . '|a' . $accessLevel);

            $this->view->assign('objectType', $objectType)
                       ->assign('source', $source)
                       ->assign($objectType, $entity)
                       ->assign('displayMode', $displayMode);

            return $this->view->fetch('external/' . $objectType . '/display.tpl');
        «ELSE»
            $templateParameters = [
                'objectType' => $objectType,
                'source' => $source,
                $objectType => $entity,
                'displayMode' => $displayMode
            ];
            «IF needsFeatureActivationHelper»
                $templateParameters['featureActivationHelper'] = $this->get('«appService».feature_activation_helper');
            «ENDIF»

            return $this->render('@«appName»/External/' . ucfirst($objectType) . '/display.html.twig', $templateParameters);
        «ENDIF»
    '''

    def private finderBase(Application it) '''
        «finderDocBlock(true)»
        «finderSignature»
        {
            «finderBaseImpl»
        }
    '''

    def private finderDocBlock(Application it, Boolean isBase) '''
        /**
         * Popup selector for Scribite plugins.
         * Finds items of a certain object type.
         «IF !isLegacy && !isBase»
         *
         * @Route("/finder/{objectType}/{editor}/{sort}/{sortdir}/{pos}/{num}",
         *        requirements = {"editor" = "xinha|tinymce|ckeditor", "sortdir" = "asc|desc", "pos" = "\d+", "num" = "\d+"},
         *        defaults = {"sort" = "", "sortdir" = "asc", "pos" = 1, "num" = 0},
         *        methods = {"GET"},
         *        options={"expose"=true}
         * )
         «ENDIF»
         *
         * @param string $objectType The object type
         * @param string $editor     Name of used Scribite editor
         * @param string $sort       Sorting field
         * @param string $sortdir    Sorting direction
         * @param int    $pos        Current pager position
         * @param int    $num        Amount of entries to display
         *
         * @return output The external item finder page
         «IF !isLegacy»
         *
         * @throws AccessDeniedException Thrown if the user doesn't have required permissions
         «ENDIF»
         */
    '''

    def private finderSignature(Application it) '''
        public function finder«IF isLegacy»()«ELSE»Action($objectType, $editor, $sort, $sortdir, $pos = 1, $num = 0)«ENDIF»
    '''

    def private finderBaseImpl(Application it) '''
        «IF isLegacy»
            PageUtil::addVar('stylesheet', ThemeUtil::getModuleStylesheet('«appName»'));
        «ELSE»
            PageUtil::addVar('stylesheet', '@«appName»/Resources/public/css/style.css');
        «ENDIF»

        $getData = $this->request->query;
        «IF isLegacy»
            $controllerHelper = new «appName»_Util_Controller($this->serviceManager);
        «ELSE»
            $controllerHelper = $this->get('«appService».controller_helper');
        «ENDIF»

        «IF isLegacy»
            $objectType = $getData->filter('objectType', '«getLeadingEntity.name.formatForCode»', FILTER_SANITIZE_STRING);
        «ENDIF»
        $utilArgs = «IF isLegacy»array(«ELSE»[«ENDIF»'controller' => 'external', 'action' => 'finder'«IF isLegacy»)«ELSE»]«ENDIF»;
        if (!in_array($objectType, $controllerHelper->getObjectTypes('controller', $utilArgs))) {
            $objectType = $controllerHelper->getDefaultObjectType('controllerType', $utilArgs);
        }

        «IF isLegacy»
            $this->throwForbiddenUnless(SecurityUtil::checkPermission('«appName»:' . ucfirst($objectType) . ':', '::', ACCESS_COMMENT), LogUtil::getErrorMsgPermission());
        «ELSE»
            if (!$this->hasPermission('«appName»:' . ucfirst($objectType) . ':', '::', ACCESS_COMMENT)) {
                throw new AccessDeniedException();
            }
        «ENDIF»

        «IF isLegacy»
            $entityClass = '«appName»_Entity_' . ucfirst($objectType);
            $repository = $this->entityManager->getRepository($entityClass);
            $repository->setControllerArguments(array());
        «ELSE»
            $repository = $this->get('«appService».' . $objectType . '_factory')->getRepository();
            $repository->setRequest($this->get('request_stack')->getCurrentRequest());
        «ENDIF»

        «IF isLegacy»
            $editor = $getData->filter('editor', '', FILTER_SANITIZE_STRING);
        «ENDIF»
        if (empty($editor) || !in_array($editor, «IF isLegacy»array(«ELSE»[«ENDIF»'xinha', 'tinymce', 'ckeditor'«IF isLegacy»)«ELSE»]«ENDIF»)) {
            return $this->__('Error: Invalid editor context given for external controller action.');
        }
        «IF hasCategorisableEntities»

            // fetch selected categories to reselect them in the output
            // the actual filtering is done inside the repository class
            «IF isLegacy»
                $categoryIds = ModUtil::apiFunc('«appName»', 'category', 'retrieveCategoriesFromRequest', array('ot' => $objectType, 'source' => 'GET'));
            «ELSE»
                $categoryHelper = $this->get('«appService».category_helper');
                $categoryIds = $categoryHelper->retrieveCategoriesFromRequest($objectType, 'GET');
            «ENDIF»
        «ENDIF»
        «IF isLegacy»
            $sort = $getData->filter('sort', '', FILTER_SANITIZE_STRING);
        «ENDIF»
        if (empty($sort) || !in_array($sort, $repository->getAllowedSortingFields())) {
            $sort = $repository->getDefaultSortingField();
        }

        «IF isLegacy»
            $sortdir = $getData->filter('sortdir', '', FILTER_SANITIZE_STRING);
        «ENDIF»
        $sdir = strtolower($sortdir);
        if ($sdir != 'asc' && $sdir != 'desc') {
            $sdir = 'asc';
        }

        $sortParam = $sort . ' ' . $sdir;

        // the current offset which is used to calculate the pagination
        $currentPage = (int) «IF isLegacy»$getData->filter('pos', 1, FILTER_VALIDATE_INT)«ELSE»$pos«ENDIF»;

        // the number of items displayed on a page for pagination
        $resultsPerPage = (int) «IF isLegacy»$getData->filter('num', 0, FILTER_VALIDATE_INT)«ELSE»$num«ENDIF»;
        if ($resultsPerPage == 0) {
            $resultsPerPage = $this->getVar('pageSize', 20);
        }
        $where = '';
        list($entities, $objectCount) = $repository->selectWherePaginated($where, $sortParam, $currentPage, $resultsPerPage);

        «IF hasCategorisableEntities»
            if (in_array($objectType, «IF isLegacy»array(«ELSE»[«ENDIF»'«getCategorisableEntities.map[e|e.name.formatForCode].join('\', \'')»'«IF isLegacy»)«ELSE»]«ENDIF»)) {
                «IF !isLegacy»
                $featureActivationHelper = $this->get('«appService».feature_activation_helper');
                if ($featureActivationHelper->isEnabled(FeatureActivationHelper::CATEGORIES, $objectType)) {
            	«ENDIF»
                $filteredEntities = «IF isLegacy»array()«ELSE»[]«ENDIF»;
                foreach ($entities as $entity) {
                    if (CategoryUtil::hasCategoryAccess($entity['categories'], '«appName»', ACCESS_OVERVIEW)) {
                        $filteredEntities[] = $entity;
                    }
            	}
            	$entities = $filteredEntities;
            	«IF !isLegacy»
            	}
            	«ENDIF»
            }

        «ENDIF»
        foreach ($entities as $k => $entity) {
            $entity->initWorkflow();
        }

        «IF isLegacy»
            $view = Zikula_View::getInstance('«appName»', false);

            $view->assign('editorName', $editor)
                 ->assign('objectType', $objectType)
                 ->assign('items', $entities)
                 ->assign('sort', $sort)
                 ->assign('sortdir', $sdir)
                 ->assign('currentPage', $currentPage)
                 ->assign('pager', array('numitems'     => $objectCount,
                                         'itemsperpage' => $resultsPerPage));
            «IF hasCategorisableEntities»

                // assign category properties
                $properties = null;
                if (in_array($objectType, $this->categorisableObjectTypes)) {
                    «IF isLegacy»
                        $properties = ModUtil::apiFunc('«appName»', 'category', 'getAllProperties', array('ot' => $objectType));
                    «ELSE»
                        $properties = $categoryHelper->getAllProperties($objectType);
                    «ENDIF»
                }
                $view->assign('properties', $properties)
                     ->assign('catIds', $categoryIds);
            «ENDIF»

            return $view->display('external/' . $objectType . '/find.tpl');
        «ELSE»
            $templateParameters = [
                'editorName' => $editor,
                'objectType' => $objectType,
                'items' => $entities,
                'sort' => $sort,
                'sortdir' => $sdir,
                'currentPage' => $currentPage,
                'pager', ['numitems' => $objectCount, 'itemsperpage' => $resultsPerPage]
            ];
            «IF needsFeatureActivationHelper»
                $templateParameters['featureActivationHelper'] = $this->get('«appService».feature_activation_helper');
            «ENDIF»

            $formOptions = [
                'objectType' => $objectType,
                'editorName' => $editor
            ];
            $form = $this->createForm('«appNamespace»\Form\Type\Finder\\' . ucfirst($objectType) . 'FinderType', $templateParameters, $formOptions);

            $templateParameters['finderForm'] = $form->createView();

            «/* shouldn't be necessary
            if ($form->handleRequest($request)->isValid() && $form->get('update')->isClicked()) {
                $templateParameters = array_merge($templateParameters, $form->getData());
            }

            */»
            return $this->render('@«appName»/External/' . ucfirst($objectType) . '/find.html.twig', $templateParameters);
        «ENDIF»
    '''

    def private externalImpl(Application it) '''
        «IF !isLegacy»
            namespace «appNamespace»\Controller;

            use «appNamespace»\Controller\Base\AbstractExternalController;

            use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;

        «ENDIF»
        /**
         * Controller for external calls implementation class.
         «IF !isLegacy»
         *
         * @Route("/external")
         «ENDIF»
         */
        «IF isLegacy»
        class «appName»_Controller_External extends «appName»_Controller_Base_AbstractExternal
        «ELSE»
        class ExternalController extends AbstractExternalController
        «ENDIF»
        {
            «IF !isLegacy»
                «displayImpl»

                «finderImpl»

            «ENDIF»
            // feel free to extend the external controller here
        }
    '''

    def private displayImpl(Application it) '''
        «displayDocBlock(false)»
        «displaySignature»
        {
            return parent::displayAction($ot, $id, $source, $displayMode);
        }
    '''

    def private finderImpl(Application it) '''
        «finderDocBlock(false)»
        «finderSignature»
        {
            return parent::finderAction($objectType, $editor, $sort, $sortdir, $pos, $num);
        }
    '''

    def private isLegacy(Application it) {
        targets('1.3.x')
    }
}
