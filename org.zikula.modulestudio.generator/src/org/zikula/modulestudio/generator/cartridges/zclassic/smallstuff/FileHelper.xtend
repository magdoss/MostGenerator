package org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff

import de.guite.modulestudio.metamodel.AbstractDateField
import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.BooleanField
import de.guite.modulestudio.metamodel.DecimalField
import de.guite.modulestudio.metamodel.DerivedField
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.FloatField
import de.guite.modulestudio.metamodel.IntegerField
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelInheritanceExtensions
import org.zikula.modulestudio.generator.extensions.ModelJoinExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class FileHelper {

    extension FormattingExtensions = new FormattingExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelInheritanceExtensions = new ModelInheritanceExtensions
    extension ModelJoinExtensions = new ModelJoinExtensions
    extension Utils = new Utils

    def phpFileHeader(Application it) '''
        <?php
        /**
         «phpFileHeaderImpl»
         * @version «generatedBy(timestampAllGeneratedFiles, versionAllGeneratedFiles)»
         */

    '''

    def phpFileContent(Application it, CharSequence content) '''
        «phpFileHeader»
        «content»
    '''

    def phpFileHeaderVersionClass(Application it) '''
        <?php
        /**
         «phpFileHeaderImpl»
         * @version «generatedBy(true, true)»
         */

    '''

    def private phpFileHeaderImpl(Application it) '''
        * «name».
        *
        * @copyright «author» («vendor»)
        * @license «license»
        «IF targets('1.3.x')»
            * @package «name»
        «ENDIF»
        * @author «author»«IF null !== email && email != ''» <«email»>«ENDIF».
        * @link «IF url != ''»«url»«ELSE»«msUrl»«ENDIF»«IF url != 'http://zikula.org'»
        * @link http://zikula.org«ENDIF»
    '''

    def public generatedBy(Application it, Boolean includeTimestamp, Boolean includeVersion) '''Generated by ModuleStudio «IF includeVersion»«msVersion» «ENDIF»(«msUrl»)«IF includeTimestamp» at «timestamp»«ENDIF».'''

    def msWeblink(Application it) '''
        <p class="«IF targets('1.3.x')»z«ELSE»text«ENDIF»-center">
            Powered by <a href="«msUrl»" title="Get the MOST out of Zikula!">ModuleStudio «msVersion»</a>
        </p>
    '''


    def getterAndSetterMethods(Object it, String name, String type, Boolean isMany, Boolean useHint, String init, CharSequence customImpl) '''
        «getterMethod(name, type, isMany)»
        «setterMethod(name, type, isMany, useHint, init, customImpl)»
    '''

    def getterMethod(Object it, String name, String type, Boolean isMany) '''
        /**
         * Get «name.formatForDisplay».
         *
         * @return «IF type == 'smallint' || type == 'bigint'»integer«ELSEIF type == 'datetime'»\DateTime«ELSE»«type»«ENDIF»«IF type.toLowerCase != 'array' && isMany»[]«ENDIF»
         */
        public function get«name.formatForCodeCapital»()
        {
            return $this->«name»;
        }
        «/* this last line is on purpose */»
    '''

    def setterMethod(Object it, String name, String type, Boolean isMany, Boolean useHint, String init, CharSequence customImpl) '''
        /**
         * Set «name.formatForDisplay».
         *
         * @param «IF type == 'smallint' || type == 'bigint'»integer«ELSEIF type == 'datetime'»\DateTime«ELSE»«type»«ENDIF»«IF type.toLowerCase != 'array' && isMany»[]«ENDIF» $«name».
         *
         * @return void
         */
        public function set«name.formatForCodeCapital»(«IF useHint»«type» «ENDIF»$«name»«IF init != ''» = «init»«ENDIF»)
        {
            «IF null !== customImpl && customImpl != ''»
                «customImpl»
            «ELSE»
                «setterMethodImpl(name, type)»
            «ENDIF»
        }
        «/* this last line is on purpose */»
    '''

    def private dispatch setterMethodImpl(Object it, String name, String type) '''
        $this->«name» = $«name»;
    '''

    def triggerPropertyChangeListeners(DerivedField it, String name) '''
        «IF entity instanceof Entity && (entity as Entity).hasNotifyPolicy»
            $this->_onPropertyChanged('«name.formatForCode»', $this->«name.formatForCode», $«name»);
        «ENDIF»
    '''

    def private dispatch setterMethodImpl(DerivedField it, String name, String type) '''
        «IF (entity instanceof Entity && (entity as Entity).hasNotifyPolicy) || entity.getInheritingEntities.exists[hasNotifyPolicy]»
            if ($«name» !== $this->«name.formatForCode») {
                «triggerPropertyChangeListeners(name)»
                «setterAssignment(name, type)»
            }
        «ELSE»
            «setterAssignment(name, type)»
        «ENDIF»
    '''

    def private dispatch setterMethodImpl(BooleanField it, String name, String type) '''
        if ($«name» !== $this->«name.formatForCode») {
            «triggerPropertyChangeListeners(name)»
            $this->«name» = (bool)$«name»;
        }
    '''

    def private dispatch setterAssignment(DerivedField it, String name, String type) '''
            $this->«name» = $«name»;
    '''

    def private setterAssignmentNumeric(DerivedField it, String name, String type) '''
        «val aggregators = getAggregatingRelationships»
        «IF !aggregators.empty»
            $diff = abs($this->«name» - $«name»);
        «ENDIF»
        $this->«name» = $«name»;
        «IF !aggregators.empty»
            «FOR aggregator : aggregators»
            $this->«aggregator.sourceAlias.formatForCode»->add«name.formatForCodeCapital»Without«entity.name.formatForCodeCapital»($diff);
            «ENDFOR»
        «ENDIF»
    '''

    def private dispatch setterAssignment(IntegerField it, String name, String type) '''
        «setterAssignmentNumeric(name, type)»
    '''
    def private dispatch setterAssignment(DecimalField it, String name, String type) '''
        «setterAssignmentNumeric(name, type)»
    '''
    def private dispatch setterAssignment(FloatField it, String name, String type) '''
        «setterAssignmentNumeric(name, type)»
    '''

    def private dispatch setterAssignment(AbstractDateField it, String name, String type) '''
        if (is_object($«name») && $«name» instanceOf \DateTime) {
            $this->«name» = $«name»;
        } else {
            $this->«name» = new \DateTime($«name»);
        }
    '''
}
