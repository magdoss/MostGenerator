package org.zikula.modulestudio.generator.cartridges.zclassic.controller.helper

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class SearchHelper {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension Utils = new Utils

    def generate(Application it, IMostFileSystemAccess fsa) {
        'Generating helper class for search integration'.printIfNotTesting(fsa)
        fsa.generateClassPair('Helper/SearchHelper.php', searchHelperBaseClass, searchHelperImpl)
    }

    def private searchHelperBaseClass(Application it) '''
        namespace «appNamespace»\Helper\Base;

        use Doctrine\ORM\QueryBuilder;
        use Doctrine\ORM\Query\Expr\Composite;
        use Symfony\Component\Form\Extension\Core\Type\CheckboxType;
        use Symfony\Component\Form\Extension\Core\Type\HiddenType;
        use Symfony\Component\Form\FormBuilderInterface;
        use Symfony\Component\HttpFoundation\Request;
        use Symfony\Component\HttpFoundation\RequestStack;
        use Symfony\Component\HttpFoundation\Session\SessionInterface;
        use Zikula\Common\Translator\TranslatorInterface;
        use Zikula\Common\Translator\TranslatorTrait;
        use Zikula\Core\RouteUrl;
        use Zikula\PermissionsModule\Api\ApiInterface\PermissionApiInterface;
        use Zikula\SearchModule\Entity\SearchResultEntity;
        use Zikula\SearchModule\SearchableInterface;
        use «appNamespace»\Entity\Factory\EntityFactory;
        «IF hasCategorisableEntities»
            use «appNamespace»\Helper\CategoryHelper;
        «ENDIF»
        use «appNamespace»\Helper\ControllerHelper;
        use «appNamespace»\Helper\EntityDisplayHelper;
        «IF hasCategorisableEntities»
            use «appNamespace»\Helper\FeatureActivationHelper;
        «ENDIF»

        /**
         * Search helper base class.
         */
        abstract class AbstractSearchHelper implements SearchableInterface
        {
            «searchHelperBaseImpl»
        }
    '''

    def private searchHelperBaseImpl(Application it) '''
        use TranslatorTrait;

        /**
         * @var PermissionApiInterface
         */
        protected $permissionApi;

        /**
         * @var SessionInterface
         */
        protected $session;

        /**
         * @var Request
         */
        protected $request;

        /**
         * @var EntityFactory
         */
        protected $entityFactory;

        /**
         * @var ControllerHelper
         */
        protected $controllerHelper;

        /**
         * @var EntityDisplayHelper
         */
        protected $entityDisplayHelper;
        «IF hasCategorisableEntities»

            /**
             * @var FeatureActivationHelper
             */
            protected $featureActivationHelper;

            /**
             * @var CategoryHelper
             */
            protected $categoryHelper;
        «ENDIF»

        /**
         * SearchHelper constructor.
         *
         * @param TranslatorInterface $translator          Translator service instance
         * @param PermissionApiInterface $permissionApi    PermissionApi service instance
         * @param SessionInterface    $session             Session service instance
         * @param RequestStack        $requestStack        RequestStack service instance
         * @param EntityFactory       $entityFactory       EntityFactory service instance
         * @param ControllerHelper    $controllerHelper    ControllerHelper service instance
         * @param EntityDisplayHelper $entityDisplayHelper EntityDisplayHelper service instance
         «IF hasCategorisableEntities»
         * @param FeatureActivationHelper $featureActivationHelper FeatureActivationHelper service instance
         * @param CategoryHelper      $categoryHelper      CategoryHelper service instance
         «ENDIF»
         */
        public function __construct(
            TranslatorInterface $translator,
            PermissionApiInterface $permissionApi,
            SessionInterface $session,
            RequestStack $requestStack,
            EntityFactory $entityFactory,
            ControllerHelper $controllerHelper,
            EntityDisplayHelper $entityDisplayHelper«IF hasCategorisableEntities»,
            FeatureActivationHelper $featureActivationHelper,
            CategoryHelper $categoryHelper«ENDIF»
        ) {
            $this->setTranslator($translator);
            $this->permissionApi = $permissionApi;
            $this->session = $session;
            $this->request = $requestStack->getCurrentRequest();
            $this->entityFactory = $entityFactory;
            $this->controllerHelper = $controllerHelper;
            $this->entityDisplayHelper = $entityDisplayHelper;
            «IF hasCategorisableEntities»
                $this->featureActivationHelper = $featureActivationHelper;
                $this->categoryHelper = $categoryHelper;
            «ENDIF»
        }

        «setTranslatorMethod»

        «amendForm»

        «getResults»

        «val entitiesWithStrings = getAllEntities.filter[hasAbstractStringFieldsEntity]»
        /**
         * Returns list of supported search types.
         *
         * @return array List of search types
         */
        protected function getSearchTypes()
        {
            $searchTypes = [
                «FOR entity : entitiesWithStrings»
                    '«appName.toFirstLower»«entity.nameMultiple.formatForCodeCapital»' => [
                        'value' => '«entity.name.formatForCode»',
                        'label' => $this->__('«entity.nameMultiple.formatForDisplayCapital»')
                    ]«IF entity != entitiesWithStrings.last»,«ENDIF»
                «ENDFOR»
            ];

            $allowedTypes = $this->controllerHelper->getObjectTypes('helper', ['helper' => 'search', 'action' => 'getSearchTypes']);
            $allowedSearchTypes = [];
            foreach ($searchTypes as $searchType => $typeInfo) {
                if (!in_array($typeInfo['value'], $allowedTypes)) {
                    continue;
                }
                $allowedSearchTypes[$searchType] = $typeInfo;
            }

            return $allowedSearchTypes;
        }

        «getErrors»

        «formatWhere»
    '''

    def private amendForm(Application it) '''
        /**
         * @inheritDoc
         */
        public function amendForm(FormBuilderInterface $builder)
        {
            if (!$this->permissionApi->hasPermission('«appName»::', '::', ACCESS_READ)) {
                return '';
            }

            $builder->add('active', HiddenType::class, [
                'data' => true
            ]);

            $searchTypes = $this->getSearchTypes();

            foreach ($searchTypes as $searchType => $typeInfo) {
                $builder->add('active_' . $searchType, CheckboxType::class, [
                    'value' => $typeInfo['value'],
                    'label' => $typeInfo['label'],
                    'label_attr' => ['class' => 'checkbox-inline'],
                    'required' => false
                ]);
            }
        }
    '''

    def private getResults(Application it) '''
        /**
         * @inheritDoc
         */
        public function getResults(array $words, $searchType = 'AND', $modVars = null)
        {
            if (!$this->permissionApi->hasPermission('«appName»::', '::', ACCESS_READ)) {
                return [];
            }

            // initialise array for results
            $results = [];

            // retrieve list of activated object types
            $searchTypes = $this->getSearchTypes();
            $entitiesWithDisplayAction = ['«getAllEntities.filter[hasDisplayAction].map[name.formatForCode].join('\', \'')»'];

            foreach ($searchTypes as $searchTypeCode => $typeInfo) {
                $isActivated = false;
                $searchSettings = $this->request->query->get('zikulasearchmodule_search', []);
                $moduleActivationInfo = $searchSettings['modules'];
                if (isset($moduleActivationInfo['«appName»'])) {
                    $moduleActivationInfo = $moduleActivationInfo['«appName»'];
                    $isActivated = isset($moduleActivationInfo['active_' . $searchTypeCode]);
                }
                if (!$isActivated) {
                    continue;
                }

                $objectType = $typeInfo['value'];
                $whereArray = [];
                $languageField = null;
                switch ($objectType) {
                    «FOR entity : entities.filter[hasAbstractStringFieldsEntity]»
                        case '«entity.name.formatForCode»':
                            «FOR field : entity.getAbstractStringFieldsEntity»
                                $whereArray[] = 'tbl.«field.name.formatForCode»';
                            «ENDFOR»
                            «IF entity.hasLanguageFieldsEntity»
                                $languageField = '«entity.getLanguageFieldsEntity.head.name.formatForCode»';
                            «ENDIF»
                            break;
                    «ENDFOR»
                }

                $repository = $this->entityFactory->getRepository($objectType);

                // build the search query without any joins
                $qb = $repository->genericBaseQuery('', '', false);

                // build where expression for given search type
                $whereExpr = $this->formatWhere($qb, $words, $whereArray, $searchType);
                $qb->andWhere($whereExpr);

                $query = $qb->getQuery();

                // set a sensitive limit
                $query->setFirstResult(0)
                      ->setMaxResults(250);

                // fetch the results
                $entities = $query->getResult();

                if (count($entities) == 0) {
                    continue;
                }

                $descriptionFieldName = $this->entityDisplayHelper->getDescriptionFieldName($objectType);
                $hasDisplayAction = in_array($objectType, $entitiesWithDisplayAction);

                foreach ($entities as $entity) {
                    // perform permission check
                    if (!$this->permissionApi->hasPermission('«appName»:' . ucfirst($objectType) . ':', $entity->getKey() . '::', ACCESS_OVERVIEW)) {
                        continue;
                    }
                    «IF hasCategorisableEntities»

                        if (in_array($objectType, ['«getCategorisableEntities.map[name.formatForCode].join('\', \'')»'])) {
                            if ($this->featureActivationHelper->isEnabled(FeatureActivationHelper::CATEGORIES, $objectType)) {
                                if (!$this->categoryHelper->hasPermission($entity)) {
                                    continue;
                                }
                            }
                        }
                    «ENDIF»

                    $description = !empty($descriptionFieldName) ? $entity[$descriptionFieldName] : '';
                    $created = isset($entity['createdDate']) ? $entity['createdDate'] : null;

                    $formattedTitle = $this->entityDisplayHelper->getFormattedTitle($entity);
                    $displayUrl = '';
                    if ($hasDisplayAction) {
                        $urlArgs = $entity->createUrlArgs();
                        $urlArgs['_locale'] = (null !== $languageField && !empty($entity[$languageField])) ? $entity[$languageField] : $this->request->getLocale();
                        $displayUrl = new RouteUrl('«appName.formatForDB»_' . strtolower($objectType) . '_display', $urlArgs);
                    }

                    $result = new SearchResultEntity();
                    $result->setTitle($formattedTitle)
                        ->setText($description)
                        ->setModule('«appName»')
                        ->setCreated($created)
                        ->setSesid($this->session->getId())
                        ->setUrl($displayUrl);
                    $results[] = $result;
                }
            }

            return $results;
        }
    '''

    def private getErrors(Application it) '''
        /**
         * @inheritDoc
         */
        public function getErrors()
        {
            return [];
        }
    '''

    def private formatWhere(Application it) '''
        /**
         * Construct a QueryBuilder Where orX|andX Expr instance.
         *
         * @param QueryBuilder $qb
         * @param string[] $words  List of words to query for
         * @param string[] $fields List of fields to include into query
         * @param string $searchtype AND|OR|EXACT
         *
         * @return null|Composite
         */
        protected function formatWhere(QueryBuilder $qb, array $words = [], array $fields = [], $searchtype = 'AND')
        {
            if (empty($words) || empty($fields)) {
                return null;
            }

            $method = ($searchtype == 'OR') ? 'orX' : 'andX';
            /** @var $where Composite */
            $where = $qb->expr()->$method();
            $i = 1;
            foreach ($words as $word) {
                $subWhere = $qb->expr()->orX();
                foreach ($fields as $field) {
                    $expr = $qb->expr()->like($field, "?$i");
                    $subWhere->add($expr);
                    $qb->setParameter($i, '%' . $word . '%');
                    $i++;
                }
                $where->add($subWhere);
            }

            return $where;
        }
    '''

    def private searchHelperImpl(Application it) '''
        namespace «appNamespace»\Helper;

        use «appNamespace»\Helper\Base\AbstractSearchHelper;

        /**
         * Search helper implementation class.
         */
        class SearchHelper extends AbstractSearchHelper
        {
            // feel free to extend the search helper here
        }
    '''
}
