package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class ThirdPartyListener {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension Utils = new Utils
    extension WorkflowExtensions = new WorkflowExtensions

    CommonExample commonExample = new CommonExample()

    def generate(Application it) '''
        «IF generateScribitePlugins»
            /**
             * @var Filesystem
             */
            protected $filesystem;

            /**
             * @var RequestStack
             */
            protected $requestStack;

        «ENDIF»
        «IF needsApproval && generatePendingContentSupport»
            /**
             * @var WorkflowHelper
             */
            protected $workflowHelper;

        «ENDIF»
        «IF generateScribitePlugins || (needsApproval && generatePendingContentSupport)»
            public function __construct(«IF generateScribitePlugins»Filesystem $filesystem, RequestStack $requestStack«ENDIF»«IF needsApproval && generatePendingContentSupport»«IF generateScribitePlugins», «ENDIF»WorkflowHelper $workflowHelper«ENDIF»)
            {
                «IF generateScribitePlugins»
                    $this->filesystem = $filesystem;
                    $this->requestStack = $requestStack;
                «ENDIF»
                «IF needsApproval && generatePendingContentSupport»
                    $this->workflowHelper = $workflowHelper;
                «ENDIF»
            }

        «ENDIF»
        «val needsDetailContentType = generateDetailContentType && hasDisplayActions»
        public static function getSubscribedEvents()
        {
            return [
                «IF needsApproval && generatePendingContentSupport»
                    'get.pending_content'                     => ['pendingContentListener', 5],
                «ENDIF»
                «IF !targets('2.0') && (generateListContentType || needsDetailContentType)»
                    'module.content.gettypes'                 => ['contentGetTypes', 5],
                «ENDIF»
                «IF generateScribitePlugins»
                    'module.scribite.editorhelpers'           => ['getEditorHelpers', 5],
                    'moduleplugin.ckeditor.externalplugins'   => ['getCKEditorPlugins', 5],
                    'moduleplugin.quill.externalplugins'      => ['getQuillPlugins', 5],
                    'moduleplugin.summernote.externalplugins' => ['getSummernotePlugins', 5],
                    'moduleplugin.tinymce.externalplugins'    => ['getTinyMcePlugins', 5]
                «ENDIF»
            ];
        }

        «IF needsApproval && generatePendingContentSupport»
            «pendingContentListener»
        «ENDIF»
        «IF !targets('2.0') && (generateListContentType || needsDetailContentType)»

            «contentGetTypes»
        «ENDIF»
        «IF generateScribitePlugins»

            «getEditorHelpers»

            «getCKEditorPlugins»

            «getCommonEditorPlugins('Quill')»

            «getCommonEditorPlugins('Summernote')»

            «getCommonEditorPlugins('TinyMce')»

            «getPathToModuleWebAssets»
        «ENDIF»
    '''

    def private pendingContentListener(Application it) '''
        /**
         * Listener for the `get.pending_content` event which collects information from modules
         * about pending content items waiting for approval.
         *
         «commonExample.generalEventProperties(it, false)»
         */
        public function pendingContentListener(GenericEvent $event)«IF targets('3.0')»: void«ENDIF»
        {
            «pendingContentListenerImpl»
        }
    '''

    def private pendingContentListenerImpl(Application it) '''
        «IF !needsApproval»
            // nothing required here as no entities use enhanced workflows including approval actions
        «ELSEIF !generatePendingContentSupport»
            // pending content support is disabled in generator settings
            // however, we keep this empty stub to prevent errors if the event handler
            // was already registered before
        «ELSE»
            $collection = new Container('«appName»');
            $amounts = $this->workflowHelper->collectAmountOfModerationItems();
            if (0 < count($amounts)) {
                foreach ($amounts as $amountInfo) {
                    $aggregateType = $amountInfo['aggregateType'];
                    $description = $amountInfo['description'];
                    $amount = $amountInfo['amount'];
                    $route = '«appName.toLowerCase»_' . strtolower($amountInfo['objectType']) . '_adminview';
                    $routeArgs = [
                        'workflowState' => $amountInfo['state']
                    ];
                    $item = new PendingContentCollectible($aggregateType, $description, $amount, $route, $routeArgs);
                    $collection->add($item);
                }

                // add collected items for pending content
                if (0 < $collection->count()) {
                    $event->getSubject()->add($collection);
                }
            }
        «ENDIF»
    '''

    def private contentGetTypes(Application it) '''
        /**
         * Listener for the `module.content.gettypes` event.
         *
         * This event occurs when the Content module is 'searching' for Content plugins.
         * The subject is an instance of Content_Types.
         * You can register custom content types as well as custom layout types.
         *
         «commonExample.generalEventProperties(it, false)»
         */
        public function contentGetTypes(\Zikula_Event $event)«IF targets('3.0')»: void«ENDIF»
        {
            «contentGetTypesImpl»
        }
    '''

    def private contentGetTypesImpl(Application it) '''
        // intended is using the add() method to add a plugin like below
        $types = $event->getSubject();

        «IF generateDetailContentType && hasDisplayActions»

            // plugin for showing a single item
            $types->add('«appName»_ContentType_Item');
        «ENDIF»
        «IF generateListContentType»

            // plugin for showing a list of multiple items
            $types->add('«appName»_ContentType_ItemList');
        «ENDIF»
    '''

    def private getEditorHelpers(Application it) '''
        /**
         * Listener for the `module.scribite.editorhelpers` event.
         *
         * This occurs when Scribite adds pagevars to the editor page.
         * «appName» will use this to add a javascript helper to add custom items.
         *
         «commonExample.generalEventProperties(it, false)»
         */
        public function getEditorHelpers(EditorHelperEvent $event)«IF targets('3.0')»: void«ENDIF»
        {
            // install assets for Scribite plugins
            $targetDir = '«IF targets('3.0')»public«ELSE»web«ENDIF»/modules/«vendorAndName.toLowerCase»';
            if (!$this->filesystem->exists($targetDir)) {
                $moduleDirectory = str_replace('Listener/Base', '', __DIR__);
                if (is_dir($originDir = $moduleDirectory . 'Resources/public')) {
                    $this->filesystem->symlink($originDir, $targetDir, true);
                }
            }

            $event->getHelperCollection()->add(
                [
                    'module' => '«appName»',
                    'type' => 'javascript',
                    'path' => $this->getPathToModuleWebAssets() . 'js/«appName».Finder.js'
                ]
            );
        }
    '''

    def private getCKEditorPlugins(Application it) '''
        /**
         * Listener for the `moduleplugin.ckeditor.externalplugins` event.
         *
         * Adds external plugin to CKEditor.
         *
         «commonExample.generalEventProperties(it, false)»
         */
        public function getCKEditorPlugins(GenericEvent $event)«IF targets('3.0')»: void«ENDIF»
        {
            $event->getSubject()->add([
                'name' => '«appName.formatForDB»',
                'path' => $this->getPathToModuleWebAssets() . 'scribite/CKEditor/«appName.formatForDB»/',
                'file' => 'plugin.js',
                'img' => 'ed_«appName.formatForDB».gif'
            ]);
        }
    '''

    def private getCommonEditorPlugins(Application it, String editorName) '''
        /**
         * Listener for the `moduleplugin.«editorName.toLowerCase».externalplugins` event.
         *
         * Adds external plugin to «editorName».
         *
         «commonExample.generalEventProperties(it, false)»
         */
        public function get«editorName»Plugins(GenericEvent $event)«IF targets('3.0')»: void«ENDIF»
        {
            $event->getSubject()->add([
                'name' => '«appName.formatForDB»',
                'path' => $this->getPathToModuleWebAssets() . 'scribite/«editorName»/«appName.formatForDB»/plugin.js'
            ]);
        }
    '''

    def private getPathToModuleWebAssets(Application it) '''
        /**
         * Returns base path where module assets are located.
         «IF !targets('3.0')»
         *
         * @return string
         «ENDIF»
         */
        protected function getPathToModuleWebAssets()«IF targets('3.0')»: string«ENDIF»
        {
            return $this->requestStack->getCurrentRequest()->getBasePath() . '«IF !targets('3.0')»/web«ENDIF»/modules/«vendorAndName.toLowerCase»/';
        }
    '''
}
