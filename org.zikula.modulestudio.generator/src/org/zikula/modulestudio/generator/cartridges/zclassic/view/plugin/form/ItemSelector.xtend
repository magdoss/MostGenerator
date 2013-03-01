package org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ItemSelector {
    @Inject extension FormattingExtensions = new FormattingExtensions()
    @Inject extension ModelBehaviourExtensions = new ModelBehaviourExtensions()
    @Inject extension NamingExtensions = new NamingExtensions()
    @Inject extension Utils = new Utils()

    FileHelper fh = new FileHelper()

    def generate(Application it, IFileSystemAccess fsa) {
        val formPluginPath = getAppSourceLibPath + 'Form/Plugin/'
        fsa.generateFile(formPluginPath + 'Base/ItemSelector.php', itemSelectorBaseFile)
        fsa.generateFile(formPluginPath + 'ItemSelector.php', itemSelectorFile)
        fsa.generateFile(viewPluginFilePath('function', 'ItemSelector'), itemSelectorPluginFile)
    }

    def private itemSelectorBaseFile(Application it) '''
        «fh.phpFileHeader(it)»
        «itemSelectorBaseImpl»
    '''

    def private itemSelectorFile(Application it) '''
        «fh.phpFileHeader(it)»
        «itemSelectorImpl»
    '''

    def private itemSelectorPluginFile(Application it) '''
        «fh.phpFileHeader(it)»
        «itemSelectorPluginImpl»
    '''

    def private itemSelectorBaseImpl(Application it) '''
        «IF !targets('1.3.5')»
            namespace «appName»\Form\Plugin\Base;

            use ModUtil;
            use PageUtil;
            use SecurityUtil;
            use ServiceUtil;
            use ThemeUtil;
            use Zikula_Form_Plugin_TextInput;
            use Zikula_Form_View;
            use Zikula_View;

        «ENDIF»
        /**
         * Item selector plugin base class.
         */
        class «IF targets('1.3.5')»«appName»_Form_Plugin_Base_«ENDIF»ItemSelector extends Zikula_Form_Plugin_TextInput
        {
            /**
             * The treated object type.
             *
             * @var string
             */
            public $objectType = '';

            /**
             * Identifier of selected object.
             *
             * @var integer
             */
            public $selectedItemId = 0;

            /**
             * Get filename of this file.
             * The information is used to re-establish the plugins on postback.
             *
             * @return string
             */
            public function getFilename()
            {
                return __FILE__;
            }

            /**
             * Create event handler.
             *
             * @param Zikula_Form_View $view    Reference to Zikula_Form_View object.
             * @param array            &$params Parameters passed from the Smarty plugin function.
             *
             * @see    Zikula_Form_AbstractPlugin
             * @return void
             */
            public function create(Zikula_Form_View $view, &$params)
            {
                $params['maxLength'] = 11;
                /*$params['width'] = '8em';*/

                // let parent plugin do the work in detail
                parent::create($view, $params);
            }

            /**
             * Helper method to determine css class.
             *
             * @see    Zikula_Form_Plugin_TextInput
             *
             * @return string the list of css classes to apply
             */
            protected function getStyleClass()
            {
                $class = parent::getStyleClass();
                return str_replace('z-form-text', 'z-form-itemlist ' . strtolower($this->objectType), $class);
            }

            /**
             * Render event handler.
             *
             * @param Zikula_Form_View $view Reference to Zikula_Form_View object.
             *
             * @return string The rendered output
             */
            public function render(Zikula_Form_View $view)
            {
                static $firstTime = true;
                if ($firstTime) {
                    PageUtil::addVar('javascript', 'prototype');
                    PageUtil::addVar('javascript', 'Zikula.UI'); // imageviewer
                    PageUtil::addVar('javascript', 'modules/«appName»/javascript/finder.js');
                    PageUtil::addVar('stylesheet', ThemeUtil::getModuleStylesheet('«appName»'));
                }
                $firstTime = false;

                if (!SecurityUtil::checkPermission('«appName»:' . ucwords($this->objectType) . ':', '::', ACCESS_COMMENT)) {
                    return false;
                }
                «IF hasCategorisableEntities»

                    $categorisableObjectTypes = array(«FOR entity : getCategorisableEntities SEPARATOR ', '»'«entity.name.formatForCode»'«ENDFOR»);
                    $catIds = array();
                    if (in_array($this->objectType, $categorisableObjectTypes)) {
                        // fetch selected categories to reselect them in the output
                        // the actual filtering is done inside the repository class
                        $catIds = ModUtil::apiFunc('«appName»', 'category', 'retrieveCategoriesFromRequest', array('ot' => $this->objectType));
                    }
                «ENDIF»

                «IF targets('1.3.5')»
                    $entityClass = '«appName»_Entity_' . ucwords($this->objectType);
                «ELSE»
                    $entityClass = '\\«appName»\\Entity\\' . ucwords($this->objectType) . 'Entity';
                «ENDIF»
                $serviceManager = ServiceUtil::getManager();
                $entityManager = $serviceManager->getService('doctrine.entitymanager');
                $repository = $entityManager->getRepository($entityClass);

                $sort = $repository->getDefaultSortingField();
                $sdir = 'asc';

                // convenience vars to make code clearer
                $where = '';
                $sortParam = $sort . ' ' . $sdir;

                $entities = $repository->selectWhere($where, $sortParam);

                $view = Zikula_View::getInstance('«appName»', false);
                $view->assign('items', $entities)
                     ->assign('selectedId', $this->selectedItemId);
            «IF hasCategorisableEntities»

                // assign category properties
                $properties = null;
                if (in_array($this->objectType, $categorisableObjectTypes)) {
                    $properties = ModUtil::apiFunc('«appName»', 'category', 'getAllProperties', array('ot' => $this->objectType));
                }
                $view->assign('properties', $properties)
                     ->assign('catIds', $catIds);
            «ENDIF»

                return $view->fetch(«IF targets('1.3.5')»'external/' . $this->objectType«ELSE»'External/' . ucwords($this->objectType)«ENDIF» . '/select.tpl');
            }

            /**
             * Decode event handler.
             *
             * @param Zikula_Form_View $view Zikula_Form_View object.
             *
             * @return void
             */
            public function decode(Zikula_Form_View $view)
            {
                parent::decode($view);
                $value = explode(';', $this->text);
                $this->objectType = $value[0];
                $this->selectedItemId = $value[1];
            }

            /**
             * Parses a value.
             *
             * @param Zikula_Form_View $view Reference to Zikula_Form_View object.
             * @param string           $text Text.
             *
             * @return string Parsed Text.
             */
            public function parseValue(Zikula_Form_View $view, $text)
            {
                $valueParts = array($this->objectType, $this->selectedItemId);
                return implode(';', $valueParts);
            }

            /**
             * Load values.
             *
             * Called internally by the plugin itself to load values from the render.
             * Can also by called when some one is calling the render object's Zikula_Form_ViewetValues.
             *
             * @param Zikula_Form_View $view    Reference to Zikula_Form_View object.
             * @param array            &$values Values to load.
             *
             * @return void
             */
            public function loadValue(Zikula_Form_View $view, &$values)
            {
                if (!$this->dataBased) {
                    return;
                }

                $value = null;

                if ($this->group == null) {
                    if (array_key_exists($this->dataField, $values)) {
                        $value = $values[$this->dataField];
                    }
                } else {
                    if (array_key_exists($this->group, $values) && array_key_exists($this->dataField, $values[$this->group])) {
                        $value = $values[$this->group][$this->dataField];
                    }
                }

                if ($value !== null) {
                    //$this->text = $this->formatValue($view, $value);
                    $value = explode(';', $value);
                    $this->objectType = $value[0];
                    $this->selectedItemId = $value[1];
                }
            }
        }
    '''

    def private itemSelectorImpl(Application it) '''
        «IF !targets('1.3.5')»
            namespace «appName»\Form\Plugin;

        «ENDIF»
        /**
         * Item selector plugin implementation class.
         */
        «IF targets('1.3.5')»
        class «appName»_Form_Plugin_ItemSelector extends «appName»_Form_Plugin_Base_ItemSelector
        «ELSE»
        class ItemSelector extends Base\ItemSelector
        «ENDIF»
        {
            // feel free to add your customisation here
        }
    '''

    def private itemSelectorPluginImpl(Application it) '''
        /**
         * The «appName.formatForDB»ItemSelector plugin provides items for a dropdown selector.
         *
         * @param  array            $params All attributes passed to this function from the template.
         * @param  Zikula_Form_View $view   Reference to the view object.
         *
         * @return string The output of the plugin.
         */
        function smarty_function_«appName.formatForDB»ItemSelector($params, $view)
        {
            return $view->registerPlugin('«IF targets('1.3.5')»«appName»_Form_Plugin_ItemSelector«ELSE»\\«appName»\\Form\\Plugin\\ItemSelector«ENDIF»', $params);
        }
    '''
}
