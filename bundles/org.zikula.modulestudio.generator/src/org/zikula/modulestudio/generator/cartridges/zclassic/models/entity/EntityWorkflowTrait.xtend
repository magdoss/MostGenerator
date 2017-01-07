package org.zikula.modulestudio.generator.cartridges.zclassic.models.entity

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class EntityWorkflowTrait {

    extension FormattingExtensions = new FormattingExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    FileHelper fh = new FileHelper

    def generate(Application it, IFileSystemAccess fsa) {
        val filePath = getAppSourceLibPath + 'Traits/EntityWorkflowTrait.php'
        if (!shouldBeSkipped(filePath)) {
            if (shouldBeMarked(filePath)) {
                fsa.generateFile(filePath.replace('.php', '.generated.php'), fh.phpFileContent(it, traitFile))
            } else {
                fsa.generateFile(filePath, fh.phpFileContent(it, traitFile))
            }
        }
    }

    def private traitFile(Application it) '''
        namespace «appNamespace»\Traits;

        use FormUtil;
        use ServiceUtil;
        use Zikula_Workflow_Util;

        /**
         * Workflow trait implementation class.
         */
        trait EntityWorkflowTrait
        {
            «traitImpl»
        }
    '''

    def private traitImpl(Application it) '''
        /**
         * @var array The current workflow data of this object
         */
        protected $__WORKFLOW__ = [];

        «fh.getterAndSetterMethods(it, '__WORKFLOW__', 'array', false, true, true, '[]', '')»
        «getWorkflowIdColumn»

        «initWorkflow»

        «resetWorkflow»

    '''

    def private getWorkflowIdColumn(Application it) '''
        /**
         * Returns the name of the primary identifier field.
         * For entities with composite keys the first identifier field is used.
         *
         * @return string Identifier field name
         */
        public function getWorkflowIdColumn()
        {
            $entityClass = '«vendor.formatForCodeCapital»«name.formatForCodeCapital»Module:' . ucfirst($this->get_objectType()) . 'Entity';

            $entityManager = ServiceUtil::get('«entityManagerService»');
            $meta = $entityManager->getClassMetadata($entityClass);

            return $meta->getSingleIdentifierFieldName();
        }
    '''

    def private initWorkflow(Application it) '''
        /**
         * Sets/retrieves the workflow details.
         *
         * @param boolean $forceLoading load the workflow record
         *
         * @throws RuntimeException Thrown if retrieving the workflow object fails
         */
        public function initWorkflow($forceLoading = false)
        {
            $currentFunc = FormUtil::getPassedValue('func', 'index', 'GETPOST', FILTER_SANITIZE_STRING);
            $isReuse = FormUtil::getPassedValue('astemplate', '', 'GETPOST', FILTER_SANITIZE_STRING);

            «loadWorkflow»
        }
    '''

    def private loadWorkflow(Application it) '''
        $serviceManager = ServiceUtil::getManager();
        $translator = $serviceManager->get('translator.default');
        «IF amountOfExampleRows > 0»
            $workflowHelper = new \«appNamespace»\Helper\WorkflowHelper($serviceManager, $translator);
        «ELSE»
            $workflowHelper = $serviceManager->get('«appService».workflow_helper');
        «ENDIF»

        $objectType = $this->get_objectType();
        $idColumn = $this->getWorkflowIdColumn();

        // apply workflow with most important information
        $schemaName = $workflowHelper->getWorkflowName($objectType);
        $this['__WORKFLOW__'] = [
            'module' => '«appName»',
            'state' => $this->getWorkflowState(),
            'obj_table' => $objectType,
            'obj_idcolumn' => $idColumn,
            'obj_id' => $this[$idColumn],
            'schemaname' => $schemaName
        ];

        // load the real workflow only when required (e. g. when func is edit or delete)
        if ((!in_array($currentFunc, ['index', 'view', 'display']) && empty($isReuse)) || $forceLoading) {
            $result = Zikula_Workflow_Util::getWorkflowForObject($this, $objectType, $idColumn, '«appName»');
            if (!$result) {
                $flashBag = $serviceManager->get('session')->getFlashBag();
                $flashBag->add('error', $translator->__('Error! Could not load the associated workflow.'));
            }
        }

        if (!is_object($this['__WORKFLOW__']) && !isset($this['__WORKFLOW__']['schemaname'])) {
            $workflow = $this['__WORKFLOW__'];
            $workflow['schemaname'] = $schemaName;
            $this['__WORKFLOW__'] = $workflow;
        }
    '''

    def private resetWorkflow(Application it) '''
        /**
         * Resets workflow data back to initial state.
         * This is for example used during cloning an entity object.
         */
        public function resetWorkflow()
        {
            $this->setWorkflowState('initial');

            $workflowHelper = ServiceUtil::get('«appService».workflow_helper');

            $schemaName = $workflowHelper->getWorkflowName($this->get_objectType());
            $this['__WORKFLOW__'] = [
                'module' => '«appName»',
                'state' => $this->getWorkflowState(),
                'obj_table' => $this->get_objectType(),
                'obj_idcolumn' => $this->getWorkflowIdColumn(),
                'obj_id' => 0,
                'schemaname' => $schemaName
            ];
        }
    '''
}