package org.zikula.modulestudio.generator.cartridges.zclassic.controller.additions

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.view.additions.NewsletterView
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class Newsletter {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension Utils = new Utils

    def generate(Application it, IMostFileSystemAccess fsa) {
        if (!generateOnlyBaseClasses) {
            val pluginPath = 'NewsletterPlugin/'
            val pluginClassSuffix = 'Plugin'
            var pluginFileName = 'ItemList' + pluginClassSuffix + '.php'
            fsa.generateFile(pluginPath + pluginFileName, newsletterClass)
        }
        new NewsletterView().generate(it, fsa)
    }

    def private newsletterClass(Application it) '''
        namespace «appNamespace»\NewsletterPlugin;

        use Newsletter_AbstractPlugin;
        use Symfony\Component\DependencyInjection\ContainerAwareInterface;
        use Symfony\Component\DependencyInjection\ContainerAwareTrait;

        /**
         * Newsletter plugin class.
         */
        class ItemListPlugin extends Newsletter_AbstractPlugin implements ContainerAwareInterface
        {
            use ContainerAwareTrait;

            /**
             * ItemListPlugin constructor.
             */
            public function __construct()
            {
                $this->setContainer(\ServiceUtil::getManager());
            }

            «newsletterImpl»
        }
    '''

    def private newsletterImpl(Application it) '''
        «val itemDesc = getLeadingEntity.nameMultiple.formatForDisplay»
        /**
         * Returns a title being used in the newsletter. Should be short.
         *
         * @return string Title in newsletter
         */
        public function getTitle()
        {
            return $this->container->get('translator.default')->__('Latest «IF entities.size < 2»«itemDesc»«ELSE»«appName» items«ENDIF»');
        }

        /**
         * Returns a display name for the admin interface.
         *
         * @return string Display name in admin area
         */
        public function getDisplayName()
        {
            return $this->container->get('translator.default')->__('List of «itemDesc»«IF entities.size > 1» and other «appName» items«ENDIF»');
        }

        /**
         * Returns a description for the admin interface.
         *
         * @return string Description in admin area
         */
        public function getDescription()
        {
            return $this->container->get('translator.default')->__('This plugin shows a list of «itemDesc»«IF entities.size > 1» and other items«ENDIF» of the «appName» module.');
        }

        /**
         * Determines whether this plugin is active or not.
         * An inactive plugin is not shown in the newsletter.
         *
         * @return boolean Whether the plugin is available or not
         */
        public function pluginAvailable()
        {
            return $this->container->get('kernel')->isBundle($this->modname);
        }

        /**
         * Returns custom plugin variables.
         *
         * @return array List of variables
         */
        public function getParameters()
        {
            $translator = $this->container->get('translator.default');

            $objectTypes = [];
            if ($this->pluginAvailable()) {
                «FOR entity : getAllEntities»
                    $objectTypes['«entity.name.formatForCode»'] = ['name' => $translator->__('«entity.nameMultiple.formatForDisplayCapital»')];
                «ENDFOR»
            }

            $active = $this->getPluginVar('ObjectTypes', []);
            foreach ($objectTypes as $k => $v) {
                $objectTypes[$k]['nwactive'] = in_array($k, $active);
            }

            $args = $this->getPluginVar('Args', []);

            return [
                'number' => 1,
                'param'  => [
                    'ObjectTypes'=> $objectTypes,
                    'Args' => $args
                ]
            ];
        }

        /**
         * Sets custom plugin variables.
         */
        public function setParameters()
        {
            // Object types to be used in the newsletter
            $request = $this->container->get('request_stack')->getCurrentRequest();
            $objectTypes = $request->request->get($this->modname . 'ObjectTypes', []);

            $this->setPluginVar('ObjectTypes', array_keys($objectTypes));

            // Additional arguments
            $args = $request->request->get($this->modname . 'Args', []);

            $this->setPluginVar('Args', $args);
        }

        /**
         * Returns data for the Newsletter plugin.
         *
         * @param \DateTimeInterface $filterAfterDate Optional date filter (items should be newer), format yyyy-mm-dd hh:mm:ss or null if not set
         *
         * @return array List of affected content items
         */
        public function getPluginData($filterAfterDate = null)
        {
            if (!$this->pluginAvailable()) {
                return [];
            }

            // collect data for each activated object type
            $itemsGrouped = $this->getItemsPerObjectType($filterAfterDate);

            // now flatten for presentation
            $items = [];
            if ($itemsGrouped) {
                foreach ($itemsGrouped as $objectTypes => $itemList) {
                    foreach ($itemList as $item) {
                        $items[] = $item;
                    }
                }
            }

            return $items;
        }

        /**
         * Collects newsletter data for each activated object type.
         *
         * @param \DateTimeInterface $filterAfterDate Optional date filter (items should be newer), format yyyy-mm-dd hh:mm:ss or null if not set
         *
         * @return array Data grouped by object type
         */
        protected function getItemsPerObjectType($filterAfterDate = null)
        {
            $objectTypes = $this->getPluginVar('ObjectTypes', []);
            $args = $this->getPluginVar('Args', []);

            $permissionApi = $this->container->get('zikula_permissions_module.api.permission');

            $output = [];

            foreach ($objectTypes as $objectType) {
                if (!$permissionApi->hasPermission($this->modname . ':' . ucfirst($objectType) . ':', '::', ACCESS_READ, $this->userNewsletter)) {
                    // the newsletter has no permission for these items
                    continue;
                }

                $otArgs = isset($args[$objectType]) ? $args[$objectType] : [];
                $otArgs['objectType'] = $objectType;

                // perform the data selection
                $output[$objectType] = $this->selectPluginData($otArgs, $filterAfterDate);
            }

            return $output;
        }

        /**
         * Performs the internal data selection.
         *
         * @param array              $args            Arguments array (contains object type)
         * @param \DateTimeInterface $filterAfterDate Optional date filter (items should be newer), format yyyy-mm-dd hh:mm:ss or null if not set
         *
         * @return array List of selected items
         */
        protected function selectPluginData(array $args = [], $filterAfterDate = null)
        {
            $objectType = $args['objectType'];
            $entityDisplayHelper = $this->container->get('«appService».entity_display_helper');
            $repository = $this->container->get('«appService».entity_factory')->getRepository($objectType);

            // create query
            $where = isset($args['filter']) ? $args['filter'] : '';
            $orderBy = $this->container->get('«appService».model_helper')->resolveSortParameter($objectType, $args['sorting']);
            $qb = $repository->getListQueryBuilder($where, $orderBy);

            if ($filterAfterDate) {
                $startDateFieldName = $entityDisplayHelper->getStartDateFieldName($objectType);
                if ($startDateFieldName != '') {
                    $qb->andWhere('tbl.' . $startDateFieldName . ' > :afterDate')
                       ->setParameter('afterDate', $filterAfterDate);
                }
            }

            // get objects from database
            $currentPage = 1;
            $resultsPerPage = isset($args['amount']) && is_numeric($args['amount']) ? $args['amount'] : $this->nItems;
            $query = $repository->getSelectWherePaginatedQuery($qb, $currentPage, $resultsPerPage);
            try {
                list($entities, $objectCount) = $repository->retrieveCollectionResult($query, true);
            } catch (\Exception $exception) {
                $entities = [];
                $objectCount = 0;
            }

            // post processing
            $descriptionFieldName = $entityDisplayHelper->getDescriptionFieldName($objectType);
            «IF hasImageFields»
                $previewFieldName = $entityDisplayHelper->getPreviewFieldName($objectType);
            «ENDIF»

            «IF hasDisplayActions»
                $hasDisplayPage = in_array($objectType, ['«getAllEntities.filter[hasDisplayAction].map[name.formatForCode].join('\', \'')»']);
                $router = $this->container->get('router');
            «ENDIF»
            $items = [];
            foreach ($entities as $k => $item) {
                $items[$k] = [];

                // Set title of this item.
                $items[$k]['nl_title'] = $entityDisplayHelper->getFormattedTitle($item);

                «IF hasDisplayActions»
                    if ($hasDisplayPage) {
                        // Set (full qualified) link of title
                        $urlArgs = $item->createUrlArgs();
                        $urlArgs['lang'] = $this->lang;
                        $items[$k]['nl_url_title'] = $router->generate('«appName.formatForDB»_' . strtolower($objectType) . '_display', $urlArgs, true);
                    } else {
                        $items[$k]['nl_url_title'] = null;
                    }
                «ELSE»
                    $items[$k]['nl_url_title'] = null;
                «ENDIF»

                // Set main content of the item.
                $items[$k]['nl_content'] = $descriptionFieldName ? $item[$descriptionFieldName] : '';

                // Url for further reading. In this case it is the same as used for the title.
                $items[$k]['nl_url_readmore'] = $items[$k]['nl_url_title'];

                // A picture to display in Newsletter next to the item
                «IF hasImageFields»
                    $items[$k]['nl_picture'] = $previewFieldName != '' && !empty($item[$previewFieldName]) ? $item[$previewFieldName]->getPathname() : '';
                «ELSE»
                    $items[$k]['nl_picture'] = '';
                «ENDIF»
            }

            return $items;
        }
    '''
}
