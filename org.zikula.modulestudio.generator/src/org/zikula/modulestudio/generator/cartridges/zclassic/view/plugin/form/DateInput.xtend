package org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class DateInput {
    extension FormattingExtensions = new FormattingExtensions()
    extension NamingExtensions = new NamingExtensions()
    extension Utils = new Utils()

    FileHelper fh = new FileHelper()

    def generate(Application it, IFileSystemAccess fsa) {
        generateClassPair(fsa, getAppSourceLibPath + 'Form/Plugin/DateInput.php',
            fh.phpFileContent(it, formDateInputBaseImpl), fh.phpFileContent(it, formDateInputImpl)
        )
        if (!shouldBeSkipped(viewPluginFilePath('function', 'DateInput'))) {
            fsa.generateFile(viewPluginFilePath('function', 'DateInput'), fh.phpFileContent(it, formDateInputPluginImpl))
        }
    }

    def private formDateInputBaseImpl(Application it) '''
        «IF !targets('1.3.x')»
            namespace «appNamespace»\Form\Plugin\Base;

            use DateUtil;
            use Zikula_Form_Plugin_DateInput;
            use Zikula_Form_View;
            use ZLanguage;

        «ENDIF»
        /**
         * Date value input. Not ready for datetime fields, only for raw dates.
         *
         * You can also use all of the features from the Zikula_Form_Plugin_DateInput plugin since
         * the date input inherits from it.
         */
        class «IF targets('1.3.x')»«appName»_Form_Plugin_Base_«ENDIF»DateInput extends Zikula_Form_Plugin_DateInput
        {
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
                $this->readOnly = isset($params['readOnly']) ? $params['readOnly'] : false;
        
                // let parent plugin do the work in detail
                parent::create($view, $params);
            }

            /**
             * Helper method to determine css class.
             *
             * @see Zikula_Form_Plugin_TextInput
             *
             * @return string the list of css classes to apply
             */
            protected function getStyleClass()
            {
                $class = parent::getStyleClass();

                return str_replace('z-form-text', 'z-form-date', $class);
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
                if (!empty($this->defaultValue) && !$view->isPostBack()/* && empty($this->text)*/) {
                    $d = strtolower($this->defaultValue);
                    $now = getdate();
                    $date = null;
        
                    if ($d == 'now') {
                        $date = time();
                    } elseif ($d == 'today') {
                        $date = mktime(0, 0, 0, $now['mon'], $now['mday'], $now['year']);
                    } elseif ($d == 'monthstart') {
                        $date = mktime(0, 0, 0, $now['mon'], 1, $now['year']);
                    } elseif ($d == 'monthend') {
                        $daysInMonth = date('t');
                        $date = mktime(0, 0, 0, $now['mon'], $daysInMonth, $now['year']);
                    } elseif ($d == 'yearstart') {
                        $date = mktime(0, 0, 0, 1, 1, $now['year']);
                    } elseif ($d == 'yearend') {
                        $date = mktime(0, 0, 0, 12, 31, $now['year']);
                    } elseif ($d == 'custom') {
                        $date = strtotime($this->initDate);
                    }
        
                    if ($date != null) {
                        $this->text = DateUtil::getDatetime($date, $this->ifFormat, false);
                    } else {
                        $this->text = __('Unknown date');
                    }
                }
        
                if ($view->isPostBack() && !empty($this->text)) {
                    $date = strtotime($this->text);
                    $this->text = DateUtil::getDatetime($date, $this->ifFormat, false);
                }
        
                if (strlen($this->text) > 10) {
                    $this->text = substr($this->text, 0, 10);
                }
        
                $defaultDate = new \DateTime($this->text);
                list ($dateFormat, $dateFormatJs) = $this->getDateFormat();

                include_once 'lib/«IF !targets('1.3.x')»legacy/«ENDIF»viewplugins/function.jquery_datepicker.php';
        
                $params = «IF targets('1.3.x')»array(«ELSE»[«ENDIF»
                    'defaultdate' => $defaultDate,
                    'displayelement' => $this->getId(),
                    'readonly' => $this->readOnly,
                    'displayformat_datetime' => $dateFormat,
                    'displayformat_javascript' => $dateFormatJs
                «IF targets('1.3.x')»)«ELSE»]«ENDIF»;
        
                $result = smarty_function_jquery_datepicker($params, $view);

                $attributes = $this->renderAttributes($view) . ' class="' . $this->getStyleClass() . '" ';
                $idNamePattern = 'id="' . $this->getId() . '" name="' . $this->getId() . '" ';
                $result = str_replace($idNamePattern, $idNamePattern . $attributes, $result);

                return $result;
            }

            /**
             * Returns required date formats for PHP date and JavaScript.
             *
             * @return array List of date formats.
             */
            protected function getDateFormat()
            {
                $dateFormat = 'Y-m-d';
                $dateFormatJs = 'yy-mm-dd';
                if (ZLanguage::getLanguageCode() == 'de') {
                    $dateFormat = 'd.m.Y';
                    $dateFormatJs = 'dd.mm.yy';
                }

                return «IF targets('1.3.x')»array(«ELSE»[«ENDIF»$dateFormat, $dateFormatJs«IF targets('1.3.x')»)«ELSE»]«ENDIF»;
            }
        }
    '''

    def private formDateInputImpl(Application it) '''
        «IF !targets('1.3.x')»
            namespace «appNamespace»\Form\Plugin;

            use «appNamespace»\Form\Plugin\Base\DateInput as BaseDateInput;

        «ENDIF»
        /**
         * Date value input. Not ready for datetime fields, only for raw dates.
         *
         * You can also use all of the features from the Zikula_Form_Plugin_DateInput plugin since
         * the date input inherits from it.
         */
        «IF targets('1.3.x')»
        class «appName»_Form_Plugin_DateInput extends «appName»_Form_Plugin_Base_DateInput
        «ELSE»
        class DateInput extends BaseDateInput
        «ENDIF»
        {
            // feel free to add your customisation here
        }
    '''

    def private formDateInputPluginImpl(Application it) '''
        /**
         * The «appName.formatForDB»DateInput plugin handles fields carrying date data.
         *
         * @param  array            $params All attributes passed to this function from the template.
         * @param  Zikula_Form_View $view   Reference to the view object.
         *
         * @return string The output of the plugin.
         */
        function smarty_function_«appName.formatForDB»DateInput($params, $view)
        {
            return $view->registerPlugin('«IF targets('1.3.x')»«appName»_Form_Plugin_DateInput«ELSE»\\«vendor.formatForCodeCapital»\\«name.formatForCodeCapital»Module\\Form\\Plugin\\DateInput«ENDIF»', $params);
        }
    '''
}
