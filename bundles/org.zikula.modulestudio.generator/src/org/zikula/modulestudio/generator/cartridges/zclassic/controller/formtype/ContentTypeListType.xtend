package org.zikula.modulestudio.generator.cartridges.zclassic.controller.formtype

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ContentTypeListType {

    extension FormattingExtensions = new FormattingExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension Utils = new Utils

    String nsSymfonyFormType = 'Symfony\\Component\\Form\\Extension\\Core\\Type\\'

    /**
     * Entry point for list content type form type.
     */
    def generate(Application it, IMostFileSystemAccess fsa) {
        if (!generateListContentType) {
            return
        }
        fsa.generateClassPair('ContentType/Form/Type/ItemListType.php', listContentTypeBaseImpl, listContentTypeImpl)
    }

    def private listContentTypeBaseImpl(Application it) '''
        namespace «appNamespace»\ContentType\Form\Type\Base;

        «IF hasCategorisableEntities»
            use Symfony\Component\Form\CallbackTransformer;
        «ENDIF»
        use «nsSymfonyFormType»ChoiceType;
        «IF getAllEntities.size == 1»
            use «nsSymfonyFormType»HiddenType;
        «ENDIF»
        use «nsSymfonyFormType»IntegerType;
        use «nsSymfonyFormType»TextType;
        use Symfony\Component\Form\FormBuilderInterface;
        use Symfony\Component\OptionsResolver\OptionsResolver;
        «IF hasCategorisableEntities»
            use Zikula\CategoriesModule\Entity\RepositoryInterface\CategoryRepositoryInterface;
            use Zikula\CategoriesModule\Form\Type\CategoriesType;
        «ENDIF»
        use Zikula\Common\Content\AbstractContentFormType;
        use Zikula\Common\Content\ContentTypeInterface;
        use Zikula\Common\Translator\TranslatorInterface;
        «IF hasCategorisableEntities»
            use «appNamespace»\Helper\FeatureActivationHelper;
        «ENDIF»

        /**
         * List content type form type base class.
         */
        abstract class AbstractItemListType extends AbstractContentFormType
        {
            «IF hasCategorisableEntities»
                /**
                 * @var CategoryRepositoryInterface
                 */
                protected $categoryRepository;

            «ENDIF»
            /**
             * ItemListType constructor.
             *
             * @param TranslatorInterface $translator Translator service instance
             «IF hasCategorisableEntities»
             * @param CategoryRepositoryInterface $categoryRepository
             «ENDIF»
             */
            public function __construct(TranslatorInterface $translator«IF hasCategorisableEntities», CategoryRepositoryInterface $categoryRepository«ENDIF»)
            {
                $this->setTranslator($translator);
                «IF hasCategorisableEntities»
                    $this->categoryRepository = $categoryRepository;
                «ENDIF»
            }

            /**
             * @inheritDoc
             */
            public function buildForm(FormBuilderInterface $builder, array $options)
            {
                $this->addObjectTypeField($builder, $options);
                «IF hasCategorisableEntities»
                    if ($options['feature_activation_helper']->isEnabled(FeatureActivationHelper::CATEGORIES, $options['object_type'])) {
                        $this->addCategoriesField($builder, $options);
                    }
                «ENDIF»
                $this->addSortingField($builder, $options);
                $this->addAmountField($builder, $options);
                $this->addTemplateFields($builder, $options);
                $this->addFilterField($builder, $options);
            }

            «addObjectTypeField»

            «IF hasCategorisableEntities»
                «addCategoriesField»

            «ENDIF»
            «addSortingField»

            «addAmountField»

            «addTemplateFields»

            «addFilterField»

            /**
             * @inheritDoc
             */
            public function getBlockPrefix()
            {
                return '«appName.formatForDB»_contenttype_list';
            }

            /**
             * @inheritDoc
             */
            public function configureOptions(OptionsResolver $resolver)
            {
                $resolver
                    ->setDefaults([
                        'context' => ContentTypeInterface::CONTEXT_EDIT,
                        'object_type' => '«leadingEntity.name.formatForCode»'«IF hasCategorisableEntities»,
                        'is_categorisable' => false,
                        'category_helper' => null,
                        'feature_activation_helper' => null«ENDIF»
                    ])
                    ->setRequired(['object_type'])
                    «IF hasCategorisableEntities»
                        ->setDefined(['is_categorisable', 'category_helper', 'feature_activation_helper'])
                    «ENDIF»
                    ->setAllowedTypes('context', 'string')
                    ->setAllowedTypes('object_type', 'string')
                    «IF hasCategorisableEntities»
                        ->setAllowedTypes('is_categorisable', 'bool')
                        ->setAllowedTypes('category_helper', 'object')
                        ->setAllowedTypes('feature_activation_helper', 'object')
                    «ENDIF»
                    ->setAllowedValues('context', [ContentTypeInterface::CONTEXT_EDIT, ContentTypeInterface::CONTEXT_TRANSLATION])
                ;
            }
        }
    '''

    def private addObjectTypeField(Application it) '''
        /**
         * Adds an object type field.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function addObjectTypeField(FormBuilderInterface $builder, array $options = [])
        {
            $builder->add('objectType', «IF getAllEntities.size == 1»Hidden«ELSE»Choice«ENDIF»Type::class, [
                'label' => $this->__('Object type'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ':',
                'empty_data' => '«leadingEntity.name.formatForCode»'«IF getAllEntities.size > 1»,«ENDIF»
                «IF getAllEntities.size > 1»
                    'attr' => [
                        'title' => $this->__('If you change this please save the element once to reload the parameters below.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»)
                    ],
                    'help' => $this->__('If you change this please save the element once to reload the parameters below.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»),
                    'choices' => [
                        «FOR entity : getAllEntities»
                            $this->__('«entity.nameMultiple.formatForDisplayCapital»'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => '«entity.name.formatForCode»'«IF entity != getAllEntities.last»,«ENDIF»
                        «ENDFOR»
                    ],
                    'multiple' => false,
                    'expanded' => false
                «ENDIF»
            ]);
        }
    '''

    def private addCategoriesField(Application it) '''
        /**
         * Adds a categories field.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function addCategoriesField(FormBuilderInterface $builder, array $options = [])
        {
            if (!$options['is_categorisable'] || null === $options['category_helper']) {
                return;
            }

            $objectType = $options['object_type'];
            $hasMultiSelection = $options['category_helper']->hasMultipleSelection($objectType);
            $builder->add('categories', CategoriesType::class, [
                'label' => ($hasMultiSelection ? $this->__('Categories'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») : $this->__('Category'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»)) . ':',
                'empty_data' => $hasMultiSelection ? [] : null,
                'attr' => [
                    'class' => 'category-selector',
                    'title' => $this->__('This is an optional filter.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»)
                ],
                'help' => $this->__('This is an optional filter.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»),
                'required' => false,
                'multiple' => $hasMultiSelection,
                'module' => '«appName»',
                'entity' => ucfirst($objectType) . 'Entity',
                'entityCategoryClass' => '«appNamespace»\Entity\\' . ucfirst($objectType) . 'CategoryEntity',
                'showRegistryLabels' => true
            ]);

            $categoryRepository = $this->categoryRepository;
            $builder->get('categories')->addModelTransformer(new CallbackTransformer(
                function ($catIds) use ($categoryRepository, $objectType, $hasMultiSelection) {
                    $categoryMappings = [];
                    $entityCategoryClass = '«appNamespace»\Entity\\' . ucfirst($objectType) . 'CategoryEntity';

                    $catIds = is_array($catIds) ? $catIds : explode(',', $catIds);
                    foreach ($catIds as $catId) {
                        $category = $categoryRepository->find($catId);
                        if (null === $category) {
                            continue;
                        }
                        $mapping = new $entityCategoryClass(null, $category, null);
                        $categoryMappings[] = $mapping;
                    }

                    if (!$hasMultiSelection) {
                        $categoryMappings = count($categoryMappings) > 0 ? reset($categoryMappings) : null;
                    }

                    return $categoryMappings;
                },
                function ($result) use ($hasMultiSelection) {
                    $catIds = [];

                    foreach ($result as $categoryMapping) {
                        $catIds[] = $categoryMapping->getCategory()->getId();
                    }

                    return $catIds;
                }
            ));
        }
    '''

    def private addSortingField(Application it) '''
        /**
         * Adds a sorting field.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function addSortingField(FormBuilderInterface $builder, array $options = [])
        {
            $builder->add('sorting', ChoiceType::class, [
                'label' => $this->__('Sorting'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ':',
                'empty_data' => 'default',
                'choices' => [
                    $this->__('Random'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'random',
                    $this->__('Newest'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'newest',
                    $this->__('Updated'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'updated',
                    $this->__('Default'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'default'
                ],
                'multiple' => false,
                'expanded' => false
            ]);
        }
    '''

    def private addAmountField(Application it) '''
        /**
         * Adds a page size field.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function addAmountField(FormBuilderInterface $builder, array $options = [])
        {
            $builder->add('amount', IntegerType::class, [
                'label' => $this->__('Amount'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ':',
                'attr' => [
                    'maxlength' => 2,
                    'title' => $this->__('The maximum amount of items to be shown.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ' ' . $this->__('Only digits are allowed.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»)
                ],
                'help' => $this->__('The maximum amount of items to be shown.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ' ' . $this->__('Only digits are allowed.'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»),
                'empty_data' => 5,
                'scale' => 0
            ]);
        }
    '''

    def private addTemplateFields(Application it) '''
        /**
         * Adds template fields.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function addTemplateFields(FormBuilderInterface $builder, array $options = [])
        {
            $builder
                ->add('template', ChoiceType::class, [
                    'label' => $this->__('Template'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ':',
                    'empty_data' => 'itemlist_display.html.twig',
                    'choices' => [
                        $this->__('Only item titles'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'itemlist_display.html.twig',
                        $this->__('With description'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'itemlist_display_description.html.twig',
                        $this->__('Custom template'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») => 'custom'
                    ],
                    'multiple' => false,
                    'expanded' => false
                ])
                ->add('customTemplate', TextType::class, [
                    'label' => $this->__('Custom template'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ':',
                    'required' => false,
                    'attr' => [
                        'maxlength' => 80,
                        'title' => $this->__('Example'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ': itemlist_[objectType]_display.html.twig'
                    ],
                    'help' => $this->__('Example'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ': <em>itemlist_[objectType]_display.html.twig</em>'
                ])
            ;
        }
    '''

    def private addFilterField(Application it) '''
        /**
         * Adds a filter field.
         *
         * @param FormBuilderInterface $builder The form builder
         * @param array                $options The options
         */
        public function addFilterField(FormBuilderInterface $builder, array $options = [])
        {
            $builder->add('filter', TextType::class, [
                'label' => $this->__('Filter (expert option)'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ':',
                'required' => false,
                'attr' => [
                    'maxlength' => 255,
                    'title' => $this->__('Example'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ': tbl.age >= 18'
                ],
                'help' => $this->__('Example'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF») . ': tbl.age >= 18'
            ]);
        }
    '''

    def private listContentTypeImpl(Application it) '''
        namespace «appNamespace»\ContentType\Form\Type;

        use «appNamespace»\ContentType\Form\Type\Base\AbstractItemListType;

        /**
         * List content type form type implementation class.
         */
        class ItemListType extends AbstractItemListType
        {
            // feel free to extend the list content type form type class here
        }
    '''
}