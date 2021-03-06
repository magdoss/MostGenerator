package org.zikula.modulestudio.generator.cartridges.zclassic.controller.helper

import de.guite.modulestudio.metamodel.AbstractIntegerField
import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.ArrayField
import de.guite.modulestudio.metamodel.BooleanField
import de.guite.modulestudio.metamodel.DerivedField
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.JoinRelationship
import de.guite.modulestudio.metamodel.NumberField
import de.guite.modulestudio.metamodel.ObjectField
import de.guite.modulestudio.metamodel.StringField
import de.guite.modulestudio.metamodel.TextField
import de.guite.modulestudio.metamodel.UploadField
import de.guite.modulestudio.metamodel.UserField
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.extensions.DateTimeExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelJoinExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class CollectionFilterHelper {

    extension DateTimeExtensions = new DateTimeExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelJoinExtensions = new ModelJoinExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    def generate(Application it, IMostFileSystemAccess fsa) {
        'Generating helper class for filtering entity collections'.printIfNotTesting(fsa)
        fsa.generateClassPair('Helper/CollectionFilterHelper.php', collectionFilterHelperBaseClass, collectionFilterHelperImpl)
    }

    def private collectionFilterHelperBaseClass(Application it) '''
        namespace «appNamespace»\Helper\Base;

        use Doctrine\ORM\QueryBuilder;
        use Symfony\Component\HttpFoundation\RequestStack;
        use Zikula\ExtensionsModule\Api\ApiInterface\VariableApiInterface;
        «IF hasStandardFieldEntities»
            use Zikula\UsersModule\Api\ApiInterface\CurrentUserApiInterface;
            use Zikula\UsersModule\Constant as UsersConstant;
        «ENDIF»
        «IF hasCategorisableEntities»
            use «appNamespace»\Helper\CategoryHelper;
        «ENDIF»
        use «appNamespace»\Helper\PermissionHelper;

        /**
         * Entity collection filter helper base class.
         */
        abstract class AbstractCollectionFilterHelper
        {
            «helperBaseImpl»
        }
    '''

    def private helperBaseImpl(Application it) '''
        /**
         * @var RequestStack
         */
        protected $requestStack;

        /**
         * @var PermissionHelper
         */
        protected $permissionHelper;
        «IF hasStandardFieldEntities»

            /**
             * @var CurrentUserApiInterface
             */
            protected $currentUserApi;
        «ENDIF»
        «IF hasCategorisableEntities»

            /**
             * @var CategoryHelper
             */
            protected $categoryHelper;
        «ENDIF»
        «IF !getAllEntities.filter[ownerPermission].empty»

            /**
             * @var VariableApiInterface
             */
            protected $variableApi;
        «ENDIF»

        /**
         * @var bool Fallback value to determine whether only own entries should be selected or not
         */
        protected $showOnlyOwnEntries = false;
        «IF supportLocaleFilter»

            /**
             * @var bool Whether to apply a locale-based filter or not
             */
            protected $filterDataByLocale = false;
        «ENDIF»

        public function __construct(
            RequestStack $requestStack,
            PermissionHelper $permissionHelper,
            «IF hasStandardFieldEntities»
                CurrentUserApiInterface $currentUserApi,
            «ENDIF»
            «IF hasCategorisableEntities»
                CategoryHelper $categoryHelper,
            «ENDIF»
            VariableApiInterface $variableApi
        ) {
            $this->requestStack = $requestStack;
            $this->permissionHelper = $permissionHelper;
            «IF hasStandardFieldEntities»
                $this->currentUserApi = $currentUserApi;
            «ENDIF»
            «IF hasCategorisableEntities»
                $this->categoryHelper = $categoryHelper;
            «ENDIF»
            «IF !getAllEntities.filter[ownerPermission].empty»
                $this->variableApi = $variableApi;
            «ENDIF»
            $this->showOnlyOwnEntries = (bool)$variableApi->get('«appName»', 'showOnlyOwnEntries');
            «IF supportLocaleFilter»
                $this->filterDataByLocale = (bool)$variableApi->get('«appName»', 'filterDataByLocale');
            «ENDIF»
        }

        /**
         * Returns an array of additional template variables for view quick navigation forms.
         «IF !targets('3.0')»
         *
         * @param string $objectType Name of treated entity type
         * @param string $context Usage context (allowed values: controllerAction, api, actionHandler, block, contentType)
         * @param array $args Additional arguments
         *
         * @return array List of template variables to be assigned
         «ENDIF»
         */
        public function getViewQuickNavParameters(«IF targets('3.0')»string «ENDIF»$objectType = '', «IF targets('3.0')»string «ENDIF»$context = '', array $args = [])«IF targets('3.0')»: array«ENDIF»
        {
            if (!in_array($context, ['controllerAction', 'api', 'actionHandler', 'block', 'contentType'], true)) {
                $context = 'controllerAction';
            }

            «FOR entity : getAllEntities»
                if ('«entity.name.formatForCode»' === $objectType) {
                    return $this->getViewQuickNavParametersFor«entity.name.formatForCodeCapital»($context, $args);
                }
            «ENDFOR»

            return [];
        }

        /**
         * Adds quick navigation related filter options as where clauses.
         «IF !targets('3.0')»
         *
         * @param string $objectType Name of treated entity type
         * @param QueryBuilder $qb Query builder to be enhanced
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        public function addCommonViewFilters(«IF targets('3.0')»string «ENDIF»$objectType, QueryBuilder $qb)«IF targets('3.0')»: QueryBuilder«ENDIF»
        {
            «FOR entity : getAllEntities»
                if ('«entity.name.formatForCode»' === $objectType) {
                    return $this->addCommonViewFiltersFor«entity.name.formatForCodeCapital»($qb);
                }
            «ENDFOR»

            return $qb;
        }

        /**
         * Adds default filters as where clauses.
         «IF !targets('3.0')»
         *
         * @param string $objectType Name of treated entity type
         * @param QueryBuilder $qb Query builder to be enhanced
         * @param array $parameters List of determined filter options
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        public function applyDefaultFilters(«IF targets('3.0')»string «ENDIF»$objectType, QueryBuilder $qb, array $parameters = [])«IF targets('3.0')»: QueryBuilder«ENDIF»
        {
            «FOR entity : getAllEntities»
                if ('«entity.name.formatForCode»' === $objectType) {
                    return $this->applyDefaultFiltersFor«entity.name.formatForCodeCapital»($qb, $parameters);
                }
            «ENDFOR»

            return $qb;
        }
        «FOR entity : getAllEntities»

            «entity.getViewQuickNavParameters»
        «ENDFOR»
        «FOR entity : getAllEntities»

            «entity.addCommonViewFilters»
        «ENDFOR»
        «FOR entity : getAllEntities»

            «entity.applyDefaultFilters»
        «ENDFOR»
        «FOR entity : getAllEntities.filter[hasStartOrEndDateField]»

            «entity.applyDateRangeFilter»
        «ENDFOR»

        «addSearchFilter»
        «IF hasStandardFieldEntities»

            «addCreatorFilter»
        «ENDIF»
    '''

    def private getViewQuickNavParameters(Entity it) '''
        /**
         * Returns an array of additional template variables for view quick navigation forms.
         «IF !application.targets('3.0')»
         *
         * @param string $context Usage context (allowed values: controllerAction, api, actionHandler, block, contentType)
         * @param array $args Additional arguments
         *
         * @return array List of template variables to be assigned
         «ENDIF»
         */
        protected function getViewQuickNavParametersFor«name.formatForCodeCapital»(«IF application.targets('3.0')»string «ENDIF»$context = '', array $args = [])«IF application.targets('3.0')»: array«ENDIF»
        {
            $parameters = [];
            $request = $this->requestStack->getCurrentRequest();
            if (null === $request) {
                return $parameters;
            }

            «IF categorisable»
                $parameters['catId'] = $request->query->get('catId', '');
                $parameters['catIdList'] = $this->categoryHelper->retrieveCategoriesFromRequest('«name.formatForCode»', 'GET');
            «ENDIF»
            «IF !getBidirectionalIncomingJoinRelations.filter[source instanceof Entity].empty»
                «FOR relation: getBidirectionalIncomingJoinRelations.filter[source instanceof Entity]»
                    «val sourceAliasName = relation.getRelationAliasName(false)»
                    $parameters['«sourceAliasName»'] = $request->query->get('«sourceAliasName»', 0);
                «ENDFOR»
            «ENDIF»
            «IF !getOutgoingJoinRelations.filter[target instanceof Entity].empty»
                «FOR relation: getOutgoingJoinRelations.filter[target instanceof Entity]»
                    «val targetAliasName = relation.getRelationAliasName(true)»
                    $parameters['«targetAliasName»'] = $request->query->get('«targetAliasName»', 0);
                «ENDFOR»
            «ENDIF»
            «IF hasListFieldsEntity»
                «FOR field : getListFieldsEntity»
                    «val fieldName = field.name.formatForCode»
                    $parameters['«fieldName»'] = $request->query->get('«fieldName»', '');
                «ENDFOR»
            «ENDIF»
            «IF hasUserFieldsEntity»
                «FOR field : getUserFieldsEntity»
                    «val fieldName = field.name.formatForCode»
                    $parameters['«fieldName»'] = $request->query->getInt('«fieldName»', 0);
                «ENDFOR»
            «ENDIF»
            «IF hasCountryFieldsEntity»
                «FOR field : getCountryFieldsEntity»
                    «val fieldName = field.name.formatForCode»
                    $parameters['«fieldName»'] = $request->query->get('«fieldName»', '');
                «ENDFOR»
            «ENDIF»
            «IF hasLanguageFieldsEntity»
                «FOR field : getLanguageFieldsEntity»
                    «val fieldName = field.name.formatForCode»
                    $parameters['«fieldName»'] = $request->query->get('«fieldName»', '');
                «ENDFOR»
            «ENDIF»
            «IF hasLocaleFieldsEntity»
                «FOR field : getLocaleFieldsEntity»
                    «val fieldName = field.name.formatForCode»
                    $parameters['«fieldName»'] = $request->query->get('«fieldName»', '');
                «ENDFOR»
            «ENDIF»
            «IF hasAbstractStringFieldsEntity»
                $parameters['q'] = $request->query->get('q', '');
            «ENDIF»
            «IF hasBooleanFieldsEntity»
                «FOR field : getBooleanFieldsEntity»
                    «val fieldName = field.name.formatForCode»
                    $parameters['«fieldName»'] = $request->query->get('«fieldName»', '');
                «ENDFOR»
            «ENDIF»

            return $parameters;
        }
    '''

    def private addCommonViewFilters(Entity it) '''
        /**
         * Adds quick navigation related filter options as where clauses.
         «IF !application.targets('3.0')»
         *
         * @param QueryBuilder $qb Query builder to be enhanced
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        protected function addCommonViewFiltersFor«name.formatForCodeCapital»(QueryBuilder $qb)«IF application.targets('3.0')»: QueryBuilder«ENDIF»
        {
            $request = $this->requestStack->getCurrentRequest();
            if (null === $request) {
                return $qb;
            }
            $routeName = $request->get('_route', '');
            if (false !== strpos($routeName, 'edit')) {«/* fix for #547 */»
                return $qb;
            }

            $parameters = $this->getViewQuickNavParametersFor«name.formatForCodeCapital»();
            foreach ($parameters as $k => $v) {
                if (null === $v) {
                    continue;
                }
                «IF categorisable»
                    if ('catId' === $k) {
                        if (0 < (int)$v) {
                            // single category filter
                            $qb->andWhere('tblCategories.category = :category')
                               ->setParameter('category', $v);
                        }
                        continue;
                    }
                    if ('catIdList' === $k) {
                        // multi category filter«/* old 
                        $qb->andWhere('tblCategories.category IN (:categories)')
                           ->setParameter('categories', $v);*/»
                        $qb = $this->categoryHelper->buildFilterClauses($qb, '«name.formatForCode»', $v);
                        continue;
                    }
                «ENDIF»
                if (in_array($k, ['q', 'searchterm'], true)) {
                    // quick search
                    if (!empty($v)) {
                        $qb = $this->addSearchFilter('«name.formatForCode»', $qb, $v);
                    }
                    continue;
                }
                «IF hasBooleanFieldsEntity»
                    if (in_array($k, ['«getBooleanFieldsEntity.map[name.formatForCode].join('\', \'')»'], true)) {
                        // boolean filter
                        if ('no' === $v) {
                            $qb->andWhere('tbl.' . $k . ' = 0');
                        } elseif ('yes' === $v || '1' === $v) {
                            $qb->andWhere('tbl.' . $k . ' = 1');
                        }
                        continue;
                    }
                «ENDIF»
                «IF !getBidirectionalIncomingJoinRelations.filter[source instanceof Entity].filter[isManySide(false)].empty»
                    if (in_array($k, ['«getBidirectionalIncomingJoinRelations.filter[source instanceof Entity].filter[isManySide(false)].map[getRelationAliasName(false)].join('\', \'')»']) && !empty($v)) {
                        // multi-valued source of incoming relation (many2many)
                        $qb->andWhere(
                            $qb->expr()->isMemberOf(':' . $k, 'tbl.' . $k)
                        )
                            ->setParameter($k, $v)
                        ;
                        continue;
                    }
                «ENDIF»
                «IF !getOutgoingJoinRelations.filter[source instanceof Entity].filter[isManySide(true)].empty»
                    if (in_array($k, ['«getOutgoingJoinRelations.filter[source instanceof Entity].filter[isManySide(true)].map[getRelationAliasName(true)].join('\', \'')»']) && !empty($v)) {
                        // multi-valued target of outgoing relation (one2many or many2many)
                        $qb->andWhere(
                            $qb->expr()->isMemberOf(':' . $k, 'tbl.' . $k)
                        )
                            ->setParameter($k, $v)
                        ;
                        continue;
                    }
                «ENDIF»

                if (is_array($v)) {
                    continue;
                }

                // field filter
                if ((!is_numeric($v) && '' !== $v) || (is_numeric($v) && 0 < $v)) {
                    if ('workflowState' === $k && 0 === strpos($v, '!')) {
                        $qb->andWhere('tbl.' . $k . ' != :' . $k)
                           ->setParameter($k, substr($v, 1));
                    } elseif (0 === strpos($v, '%')) {
                        $qb->andWhere('tbl.' . $k . ' LIKE :' . $k)
                           ->setParameter($k, '%' . substr($v, 1) . '%');
                    «IF !getListFieldsEntity.filter[multiple].empty»
                        } elseif (in_array($k, [«FOR field : getListFieldsEntity.filter[multiple] SEPARATOR ', '»'«field.name.formatForCode»'«ENDFOR»], true)) {
                            // multi list filter
                            $qb->andWhere('tbl.' . $k . ' LIKE :' . $k)
                               ->setParameter($k, '%' . $v . '%');
                    «ENDIF»
                    } else {
                        «IF hasUserFieldsEntity»
                            if (in_array($k, ['«getUserFieldsEntity.map[name.formatForCode].join('\', \'')»'], true)) {
                                $qb->leftJoin('tbl.' . $k, 'tbl' . ucfirst($k))
                                   ->andWhere('tbl' . ucfirst($k) . '.uid = :' . $k)
                                   ->setParameter($k, $v);
                            } else {
                                $qb->andWhere('tbl.' . $k . ' = :' . $k)
                                   ->setParameter($k, $v);
                            }
                        «ELSE»
                            $qb->andWhere('tbl.' . $k . ' = :' . $k)
                               ->setParameter($k, $v);
                        «ENDIF»
                    }
                }
            }

            return $this->applyDefaultFiltersFor«name.formatForCodeCapital»($qb, $parameters);
        }
    '''

    def private applyDefaultFilters(Entity it) '''
        /**
         * Adds default filters as where clauses.
         «IF !application.targets('3.0')»
         *
         * @param QueryBuilder $qb Query builder to be enhanced
         * @param array $parameters List of determined filter options
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        protected function applyDefaultFiltersFor«name.formatForCodeCapital»(QueryBuilder $qb, array $parameters = [])«IF application.targets('3.0')»: QueryBuilder«ENDIF»
        {
            $request = $this->requestStack->getCurrentRequest();
            if (null === $request) {
                return $qb;
            }
            «IF ownerPermission || standardFields»

                «IF ownerPermission»
                    $showOnlyOwnEntries = (bool)$this->variableApi->get('«application.appName»', '«name.formatForCode»PrivateMode', false);
                «ELSEIF standardFields»
                    $showOnlyOwnEntries = (bool)$request->query->getInt('own', «IF application.targets('3.0')»(int) «ENDIF»$this->showOnlyOwnEntries);
                «ENDIF»
                if ($showOnlyOwnEntries) {
                    $qb = $this->addCreatorFilter($qb);
                }
            «ENDIF»

            $routeName = $request->get('_route', '');
            $isAdminArea = false !== strpos($routeName, '«application.appName.toLowerCase»_«name.formatForDB»_admin');
            if ($isAdminArea) {
                return $qb;
            }

            if (!array_key_exists('workflowState', $parameters) || empty($parameters['workflowState'])) {
                // per default we show approved «nameMultiple.formatForDisplay» only
                $onlineStates = ['approved'];
                «IF ownerPermission»
                    if ($showOnlyOwnEntries) {
                        // allow the owner to see his «nameMultiple.formatForDisplay»
                        $onlineStates[] = 'deferred';
                        $onlineStates[] = 'trashed';
                    }
                «ENDIF»
                $qb->andWhere('tbl.workflowState IN (:onlineStates)')
                   ->setParameter('onlineStates', $onlineStates);
            }
            «IF hasLanguageFieldsEntity || hasLocaleFieldsEntity»

                if (true === (bool)$this->filterDataByLocale) {
                    $allowedLocales = ['', $request->getLocale()];
                    «FOR field : getLanguageFieldsEntity»
                        «val fieldName = field.name.formatForCode»
                        if (!array_key_exists('«fieldName»', $parameters) || empty($parameters['«fieldName»'])) {
                            $qb->andWhere('tbl.«fieldName» IN (:current«fieldName.toFirstUpper»)')
                               ->setParameter('current«fieldName.toFirstUpper»', $allowedLocales);
                        }
                    «ENDFOR»
                    «FOR field : getLocaleFieldsEntity»
                        «val fieldName = field.name.formatForCode»
                        if (!array_key_exists('«fieldName»', $parameters) || empty($parameters['«fieldName»'])) {
                            $qb->andWhere('tbl.«fieldName» IN (:current«fieldName.toFirstUpper»)')
                               ->setParameter('current«fieldName.toFirstUpper»', $allowedLocales);
                        }
                    «ENDFOR»
                }
            «ENDIF»
            «IF hasStartOrEndDateField»

                $qb = $this->applyDateRangeFilterFor«name.formatForCodeCapital»($qb);
            «ENDIF»
            «FOR relation : getBidirectionalIncomingJoinRelations»«relation.addDateRangeFilterForJoin(false)»«ENDFOR»
            «FOR relation : getOutgoingJoinRelations»«relation.addDateRangeFilterForJoin(true)»«ENDFOR»

            return $qb;
        }
    '''

    def addDateRangeFilterForJoin(JoinRelationship it, Boolean useTarget) {
        val relatedEntity = if (useTarget) target else source
        if (relatedEntity instanceof Entity && (relatedEntity as Entity).hasStartOrEndDateField) {
            val aliasName = 'tbl' + getRelationAliasName(useTarget).formatForCodeCapital
            '''
                if (in_array('«aliasName»', $qb->getAllAliases(), true)) {
                    $qb = $this->applyDateRangeFilterFor«relatedEntity.name.formatForCodeCapital»($qb, '«aliasName»');
                }
            '''
        }
    }

    def private applyDateRangeFilter(Entity it) '''
        /**
         * Applies «IF hasStartDateField»start «IF hasEndDateField»and «ENDIF»«ENDIF»«IF hasEndDateField»end «ENDIF»date filters for selecting «nameMultiple.formatForDisplay».
         «IF !application.targets('3.0')»
         *
         * @param QueryBuilder $qb Query builder to be enhanced
         * @param string $alias Table alias
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        protected function applyDateRangeFilterFor«name.formatForCodeCapital»(QueryBuilder $qb, «IF application.targets('3.0')»string «ENDIF»$alias = 'tbl')«IF application.targets('3.0')»: QueryBuilder«ENDIF»
        {
            $request = $this->requestStack->getCurrentRequest();
            «IF hasStartDateField»
                $startDate = $request->query->get('«startDateField.name.formatForCode»', «startDateField.defaultValueForNow»);
                $qb->andWhere(«startDateField.whereClauseForDateRangeFilter('<=', 'startDate')»)
                   ->setParameter('startDate', $startDate);
                «IF null !== endDateField»

                «ENDIF»
            «ENDIF»
            «IF hasEndDateField»
                $endDate = $request->query->get('«endDateField.name.formatForCode»', «endDateField.defaultValueForNow»);
                $qb->andWhere(«endDateField.whereClauseForDateRangeFilter('>=', 'endDate')»)
                   ->setParameter('endDate', $endDate);
            «ENDIF»

            return $qb;
        }
    '''

    def private addSearchFilter(Application it) '''
        /**
         * Adds a where clause for search query.
         «IF !targets('3.0')»
         *
         * @param string $objectType Name of treated entity type
         * @param QueryBuilder $qb Query builder to be enhanced
         * @param string $fragment The fragment to search for
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        public function addSearchFilter(«IF targets('3.0')»string «ENDIF»$objectType, QueryBuilder $qb, «IF targets('3.0')»string «ENDIF»$fragment = '')«IF targets('3.0')»: QueryBuilder«ENDIF»
        {
            if ('' === $fragment) {
                return $qb;
            }

            $filters = [];
            $parameters = [];

            «FOR entity : getAllEntities»
                if ('«entity.name.formatForCode»' === $objectType) {
                    «val searchFields = entity.getDisplayFields.filter[isContainedInSearch]»
                    «FOR field : searchFields»
                        «IF field instanceof AbstractIntegerField || field instanceof NumberField»
                            if (is_numeric($fragment)) {
                                $filters[] = 'tbl.«field.name.formatForCode»«IF field instanceof UploadField»FileName«ENDIF» «IF field.isTextSearch»LIKE«ELSE»=«ENDIF» :search«field.name.formatForCodeCapital»';
                                $parameters['search«field.name.formatForCodeCapital»'] = «IF field.isTextSearch»'%' . $fragment . '%'«ELSE»$fragment«ENDIF»;
                            }
                        «ELSE»
                            $filters[] = 'tbl.«field.name.formatForCode»«IF field instanceof UploadField»FileName«ENDIF» «IF field.isTextSearch»LIKE«ELSE»=«ENDIF» :search«field.name.formatForCodeCapital»';
                            $parameters['search«field.name.formatForCodeCapital»'] = «IF field.isTextSearch»'%' . $fragment . '%'«ELSE»$fragment«ENDIF»;
                        «ENDIF»
                    «ENDFOR»
                }
            «ENDFOR»

            $qb->andWhere('(' . implode(' OR ', $filters) . ')');

            foreach ($parameters as $parameterName => $parameterValue) {
                $qb->setParameter($parameterName, $parameterValue);
            }

            return $qb;
        }
    '''

    def private addCreatorFilter(Application it) '''
        /**
         * Adds a filter for the createdBy field.
         «IF !targets('3.0')»
         *
         * @param QueryBuilder $qb Query builder to be enhanced
         * @param int $userId The user identifier used for filtering
         *
         * @return QueryBuilder Enriched query builder instance
         «ENDIF»
         */
        public function addCreatorFilter(QueryBuilder $qb, «IF targets('3.0')»int «ENDIF»$userId = null)«IF targets('3.0')»: QueryBuilder«ENDIF»
        {
            if (null === $userId) {
                $userId = $this->currentUserApi->isLoggedIn()
                    ? (int)$this->currentUserApi->get('uid')
                    : UsersConstant::USER_ID_ANONYMOUS
                ;
            }

            $qb->andWhere('tbl.createdBy = :userId')
               ->setParameter('userId', $userId);

            return $qb;
        }
    '''

    def private whereClauseForDateRangeFilter(DerivedField it, String operator, String paramName) {
        val fieldName = name.formatForCode
        if (mandatory)
            '''$alias . '.«fieldName» «operator» :«paramName»'«''»'''
        else
            '''«''»'(' . $alias . '.«fieldName» «operator» :«paramName» OR ' . $alias . '.«fieldName» IS NULL)'«''»'''
    }

    def private isContainedInSearch(DerivedField it) {
        switch it {
            BooleanField: false
            UserField: false
            ArrayField: false
            ObjectField: false
            default: true
        }
    }

    def private isTextSearch(DerivedField it) {
        switch it {
            StringField: true
            TextField: true
            default: false
        }
    }

    def private collectionFilterHelperImpl(Application it) '''
        namespace «appNamespace»\Helper;

        use «appNamespace»\Helper\Base\AbstractCollectionFilterHelper;

        /**
         * Entity collection filter helper implementation class.
         */
        class CollectionFilterHelper extends AbstractCollectionFilterHelper
        {
            // feel free to extend the collection filter helper here
        }
    '''
}
