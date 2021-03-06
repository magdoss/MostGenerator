package org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype.trait

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.JoinRelationship
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ModerationFormFieldsTrait {

    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension Utils = new Utils

    def generate(Application it, IMostFileSystemAccess fsa) {
        if (!hasStandardFieldEntities) {
            return
        }
        val filePath = 'Traits/ModerationFormFieldsTrait.php'
        fsa.generateFile(filePath, traitFile)
    }

    def private traitFile(Application it) '''
        namespace «appNamespace»\Traits;

        use Symfony\Component\Form\Extension\Core\Type\DateTimeType;
        use Symfony\Component\Form\FormBuilderInterface;
        use Zikula\UsersModule\Form\Type\UserLiveSearchType;

        /**
         * Moderation form fields trait.
         */
        trait ModerationFormFieldsTrait
        {
            «traitImpl»
        }
    '''

    def private traitImpl(Application it) '''
        /**
         * Adds special fields for moderators.
         «IF !targets('3.0')»
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array $options The options
         «ENDIF»
         */
        public function addModerationFields(FormBuilderInterface $builder, array $options = [])«IF targets('3.0')»: void«ENDIF»
        {
            if (!$options['has_moderate_permission']) {
                return;
            }
            «IF !relations.filter(JoinRelationship).empty»
                if (isset($options['inline_usage']) && $options['inline_usage']) {
                    return;
                }
            «ENDIF»

            if (
                isset($options['allow_moderation_specific_creator'])
                && $options['allow_moderation_specific_creator']
            ) {
                $builder->add('moderationSpecificCreator', UserLiveSearchType::class, [
                    'mapped' => false,
                    'label' => «IF !targets('3.0')»$this->__(«ENDIF»'Creator:'«IF !targets('3.0')»)«ENDIF»,
                    'attr' => [
                        'maxlength' => 11,
                        'title' => «IF !targets('3.0')»$this->__(«ENDIF»'Here you can choose a user which will be set as creator.'«IF !targets('3.0')»)«ENDIF»
                    ],
                    'empty_data' => 0,
                    'required' => false,
                    'help' => «IF !targets('3.0')»$this->__(«ENDIF»'Here you can choose a user which will be set as creator.'«IF !targets('3.0')»)«ENDIF»
                ]);
            }
            if (
                isset($options['allow_moderation_specific_creation_date'])
                && $options['allow_moderation_specific_creation_date']
            ) {
                $builder->add('moderationSpecificCreationDate', DateTimeType::class, [
                    'mapped' => false,
                    'label' => «IF !targets('3.0')»$this->__(«ENDIF»'Creation date:'«IF !targets('3.0')»)«ENDIF»,
                    'attr' => [
                        'class' => '',
                        'title' => «IF !targets('3.0')»$this->__(«ENDIF»'Here you can choose a custom creation date.'«IF !targets('3.0')»)«ENDIF»
                    ],
                    'empty_data' => '',
                    'required' => false,
                    'with_seconds' => true,
                    'date_widget' => 'single_text',
                    'time_widget' => 'single_text',
                    'help' => «IF !targets('3.0')»$this->__(«ENDIF»'Here you can choose a custom creation date.'«IF !targets('3.0')»)«ENDIF»
                ]);
            }
        }
    '''
}
