package org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.BoolVar
import de.guite.modulestudio.metamodel.IntVar
import de.guite.modulestudio.metamodel.ListVar
import de.guite.modulestudio.metamodel.ListVarItem
import de.guite.modulestudio.metamodel.TextVar
import de.guite.modulestudio.metamodel.Variable
import de.guite.modulestudio.metamodel.Variables
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class Config {
    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    FileHelper fh = new FileHelper
    Boolean hasUserGroupSelectors = false
    String nsSymfonyFormType = 'Symfony\\Component\\Form\\Extension\\Core\\Type\\'

    /**
     * Entry point for config form type.
     * 1.4.x only.
     */
    def generate(Application it, IFileSystemAccess fsa) {
        if (!needsConfig) {
            return
        }
        hasUserGroupSelectors = !getAllVariables.filter(IntVar).filter[isUserGroupSelector].empty
        generateClassPair(fsa, getAppSourceLibPath + 'Form/AppSettingsType.php',
            fh.phpFileContent(it, configTypeBaseImpl), fh.phpFileContent(it, configTypeImpl)
        )
    }

    def private configTypeBaseImpl(Application it) '''
        namespace «appNamespace»\Form\Base;

        use Symfony\Component\Form\AbstractType;
        use Symfony\Component\Form\FormBuilderInterface;
        use Zikula\Common\Translator\TranslatorInterface;
        use Zikula\Common\Translator\TranslatorTrait;
        use Zikula\ExtensionsModule\Api\VariableApi;

        /**
         * Configuration form type base class.
         */
        abstract class AbstractAppSettingsType extends AbstractType
        {
            use TranslatorTrait;

            /**
             * @var VariableApi
             */
            protected $variableApi;

            /**
             * @var array
             */
            protected $modVars;

            /**
             * AppSettingsType constructor.
             *
             * @param TranslatorInterface $translator  Translator service instance
             * @param VariableApi         $variableApi VariableApi service instance
             */
            public function __construct(TranslatorInterface $translator, VariableApi $variableApi)
            {
                $this->setTranslator($translator);
                $this->variableApi = $variableApi;
                $this->modVars = $this->variableApi->getAll('«appName»');
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
             * {@inheritdoc}
             */
            public function buildForm(FormBuilderInterface $builder, array $options)
            {
                «FOR varContainer : variables»
                    $this->add«varContainer.name.formatForCodeCapital»Fields($builder, $options);
                «ENDFOR»

                $builder
                    ->add('save', '«nsSymfonyFormType»SubmitType', [
                        'label' => $this->__('Update configuration'),
                        'icon' => 'fa-check',
                        'attr' => [
                            'class' => 'btn btn-success'
                        ]
                    ])
                    ->add('cancel', '«nsSymfonyFormType»SubmitType', [
                        'label' => $this->__('Cancel'),
                        'icon' => 'fa-times',
                        'attr' => [
                            'class' => 'btn btn-default',
                            'formnovalidate' => 'formnovalidate'
                        ]
                    ])
                ;
            }

            «FOR varContainer : variables»
                «varContainer.addFieldsMethod»

            «ENDFOR»
            /**
             * {@inheritdoc}
             */
            public function getBlockPrefix()
            {
                return '«appName.formatForDB»_appsettings';
            }
        }
    '''

    def private addFieldsMethod(Variables it) '''
        /**
         * Adds fields for «name.formatForDisplay» fields.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function add«name.formatForCodeCapital»Fields(FormBuilderInterface $builder, array $options)
        {
            $builder
                «FOR modvar : vars»«modvar.definition»«ENDFOR»
            ;
        }
    '''

    def private definition(Variable it) '''
        ->add('«name.formatForCode»', '«fieldType»Type', [
            'label' => $this->__('«name.formatForDisplayCapital»') . ':',
            «IF null !== documentation && documentation != ''»
                'label_attr' => [
                    'class' => 'tooltips',
                    'title' => $this->__('«documentation.replace("'", '"')»')
                ],
                'help' => $this->__('«documentation.replace("'", '"')»'),
            «ENDIF»
            'required' => false,
            'data' => $this->modVars['«name.formatForCode»'],
            'empty_data' => '«value»',
            'attr' => [
                'title' => $this->__('«titleAttribute»')
            ],«additionalOptions»
        ])
    '''

    def private dispatch fieldType(Variable it) '''«nsSymfonyFormType»Text'''
    def private dispatch titleAttribute(Variable it) '''Enter the «name.formatForDisplay».'''
    def private dispatch additionalOptions(Variable it) '''
        'max_length' => 255
    '''

    def private dispatch fieldType(IntVar it) '''«IF hasUserGroupSelectors && isUserGroupSelector»Symfony\Bridge\Doctrine\Form\Type\Entity«ELSE»«nsSymfonyFormType»Integer«ENDIF»'''
    def private dispatch titleAttribute(IntVar it) '''«IF hasUserGroupSelectors && isUserGroupSelector»Choose the «name.formatForDisplay».«ELSE»Enter the «name.formatForDisplay». Only digits are allowed.«ENDIF»'''
    def private dispatch additionalOptions(IntVar it) '''
        «IF hasUserGroupSelectors && isUserGroupSelector»
            'max_length' => 255,
            // Zikula core should provide a form type for this to hide entity details
            'class' => 'ZikulaGroupsModule:GroupEntity',
            'choice_label' => 'name'
        «ELSE»
            'max_length' => «IF isShrinkDimensionField»4«ELSE»255«ENDIF»,
            'scale' => 0«IF isShrinkDimensionField»,
            'input_group' => ['right' => $this->__('pixels')]«ENDIF»
        «ENDIF»
    '''

    def private isShrinkDimensionField(Variable it) {
        name.formatForCode.startsWith('shrinkWidth') || name.formatForCode.startsWith('shrinkHeight')
    }

    def private dispatch fieldType(TextVar it) '''«nsSymfonyFormType»Text«IF multiline»area«ENDIF»'''
    def private dispatch additionalOptions(TextVar it) '''
        «IF maxLength > 0 || !multiline»
            'max_length' => «IF maxLength > 0»«maxLength»«ELSEIF !multiline»255«ENDIF»
        «ENDIF»
    '''

    def private dispatch fieldType(BoolVar it) '''«nsSymfonyFormType»Checkbox'''
    def private dispatch titleAttribute(BoolVar it) '''The «name.formatForDisplay» option.'''
    def private dispatch additionalOptions(BoolVar it) ''''''

    def private dispatch fieldType(ListVar it) '''«nsSymfonyFormType»Choice'''
    def private dispatch titleAttribute(ListVar it) '''Choose the «name.formatForDisplay».'''
    def private dispatch additionalOptions(ListVar it) '''
        'choices' => [
            «FOR item : items»«item.itemDefinition»«IF item != items.last»,«ENDIF»«ENDFOR»
        ],
        'choices_as_values' => true,
        'multiple' => «multiple.displayBool»
    '''

    def private itemDefinition(ListVarItem it) '''
        $this->__('«name.formatForCode»') => '«name.formatForDisplayCapital»'
    '''

    def private configTypeImpl(Application it) '''
        namespace «appNamespace»\Form;

        use «appNamespace»\Form\Base\AbstractAppSettingsType;

        /**
         * Configuration form type implementation class.
         */
        class AppSettingsType extends AbstractAppSettingsType
        {
            // feel free to extend the base form type class here
        }
    '''
}
