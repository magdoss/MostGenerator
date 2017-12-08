package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class ThirdParty {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension NamingExtensions = new NamingExtensions
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
             * @var Request
             */
            protected $request;

        «ENDIF»
        «IF needsApproval && generatePendingContentSupport»
            /**
             * @var WorkflowHelper
             */
            protected $workflowHelper;

        «ENDIF»
        «IF generateScribitePlugins || (needsApproval && generatePendingContentSupport)»
            /**
             * ThirdPartyListener constructor.
             *
             «IF generateScribitePlugins»
             * @param Filesystem   $filesystem   Filesystem service instance
             * @param RequestStack $requestStack RequestStack service instance
             «ENDIF»
             «IF needsApproval && generatePendingContentSupport»
             * @param WorkflowHelper $workflowHelper WorkflowHelper service instance
             «ENDIF»
             *
             * @return void
             */
            public function __construct(«IF generateScribitePlugins»Filesystem $filesystem, RequestStack $requestStack«ENDIF»«IF needsApproval && generatePendingContentSupport»«IF generateScribitePlugins», «ENDIF»WorkflowHelper $workflowHelper«ENDIF»)
            {
                «IF generateScribitePlugins»
                    $this->filesystem = $filesystem;
                    $this->request = $requestStack->getCurrentRequest();
                «ENDIF»
                «IF needsApproval && generatePendingContentSupport»
                    $this->workflowHelper = $workflowHelper;
                «ENDIF»
            }

        «ENDIF»
        «val needsDetailContentType = generateDetailContentType && hasDisplayActions»
        /**
         * Makes our handlers known to the event system.
         */
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
        «IF !targets('2.0')»
            «IF generateListContentType || needsDetailContentType»

                «contentGetTypes»
            «ENDIF»
        «ENDIF»
        «IF generateScribitePlugins»

            «getEditorHelpers»

            «getCKEditorPlugins»

            «getCommonEditorPlugins('Quill')»

            «getCommonEditorPlugins('Summernote')»

            «getCommonEditorPlugins('TinyMce')»
        «ENDIF»
    '''

    def private pendingContentListener(Application it) '''
        /**
         * Listener for the `get.pending_content` event with registration requests and
         * other submitted data pending approval.
         *
         * When a 'get.pending_content' event is fired, the Users module will respond with the
         * number of registration requests that are pending administrator approval. The number
         * pending may not equal the total number of outstanding registration requests, depending
         * on how the 'moderation_order' module configuration variable is set, and whether e-mail
         * address verification is required.
         * If the 'moderation_order' variable is set to require approval after e-mail verification
         * (and e-mail verification is also required) then the number of pending registration
         * requests will equal the number of registration requested that have completed the
         * verification process but have not yet been approved. For other values of
         * 'moderation_order', the number should equal the number of registration requests that
         * have not yet been approved, without regard to their current e-mail verification state.
         * If moderation of registrations is not enabled, then the value will always be 0.
         * In accordance with the 'get_pending_content' conventions, the count of pending
         * registrations, along with information necessary to access the detailed list, is
         * assemped as a {@link Zikula_Provider_AggregateItem} and added to the event
         * subject's collection.
         *
         «commonExample.generalEventProperties(it)»
         *
         * @param GenericEvent $event The event instance
         */
        public function pendingContentListener(GenericEvent $event)
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
            $modname = '«appName»';
            $useJoins = false;

            $collection = new Container($modname);
            $amounts = $this->workflowHelper->collectAmountOfModerationItems();
            if (count($amounts) > 0) {
                foreach ($amounts as $amountInfo) {
                    $aggregateType = $amountInfo['aggregateType'];
                    $description = $amountInfo['description'];
                    $amount = $amountInfo['amount'];
                    $viewArgs = [
                        'workflowState' => $amountInfo['state']
                    ];
                    $aggregateItem = new AggregateItem($aggregateType, $description, $amount, $amountInfo['objectType'], 'adminview', $viewArgs);
                    $collection->add($aggregateItem);
                }

                // add collected items for pending content
                if ($collection->count() > 0) {
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
         «commonExample.generalEventProperties(it)»
         *
         * @param \Zikula_Event $event The event instance
         */
        public function contentGetTypes(\Zikula_Event $event)
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
         «commonExample.generalEventProperties(it)»
         *
         * @param EditorHelperEvent $event The event instance
         */
        public function getEditorHelpers(EditorHelperEvent $event)
        {
            // install assets for Scribite plugins
            $targetDir = 'web/modules/«vendorAndName.toLowerCase»';
            $finder = new Finder();
            if (!$this->filesystem->exists($targetDir)) {
                $this->filesystem->mkdir($targetDir, 0777);
                if (is_dir($originDir = '«relativeAppRootPath»/Resources/public')) {
                    $this->filesystem->mirror($originDir, $targetDir, Finder::create()->in($originDir));
                }
                if (is_dir($originDir = '«relativeAppRootPath»/Resources/scribite')) {
                    $targetDir .= '/scribite';
                    $this->filesystem->mkdir($targetDir, 0777);
                    $this->filesystem->mirror($originDir, $targetDir, Finder::create()->in($originDir));
                }
            }

            $event->getHelperCollection()->add(
                [
                    'module' => '«appName»',
                    'type' => 'javascript',
                    'path' => $this->request->getBasePath() . '/web/modules/«vendorAndName.toLowerCase»/js/«appName».Finder.js'
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
         «commonExample.generalEventProperties(it)»
         *
         * @param GenericEvent $event The event instance
         */
        public function getCKEditorPlugins(GenericEvent $event)
        {
            $event->getSubject()->add([
                'name' => '«appName.formatForDB»',
                'path' => $this->request->getBasePath() . '/web/modules/«vendorAndName.toLowerCase»/scribite/CKEditor/«appName.formatForDB»/',
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
         «commonExample.generalEventProperties(it)»
         *
         * @param GenericEvent $event The event instance
         */
        public function get«editorName»Plugins(GenericEvent $event)
        {
            $event->getSubject()->add([
                'name' => '«appName.formatForDB»',
                'path' => $this->request->getBasePath() . '/web/modules/«vendorAndName.toLowerCase»/scribite/«editorName»/«appName.formatForDB»/plugin.js'
            ]);
        }
    '''
}
