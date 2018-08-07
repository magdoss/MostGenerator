package org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff

import de.guite.modulestudio.metamodel.AbstractIntegerField
import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.BooleanField
import de.guite.modulestudio.metamodel.DatetimeField
import de.guite.modulestudio.metamodel.DerivedField
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.IntegerField
import de.guite.modulestudio.metamodel.NumberField
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelInheritanceExtensions
import org.zikula.modulestudio.generator.extensions.ModelJoinExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class FileHelper {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelInheritanceExtensions = new ModelInheritanceExtensions
    extension ModelJoinExtensions = new ModelJoinExtensions
    extension Utils = new Utils

    def msWeblink(Application it) '''
        <p class="text-center">
            Powered by <a href="«msUrl»" title="Get the MOST out of Zikula!">ModuleStudio «msVersion»</a>
        </p>
    '''

    def getterAndSetterMethods(Object it, String name, String type, Boolean isMany, Boolean nullable, Boolean useHint, String init, CharSequence customImpl) '''
        «getterMethod(name, type, isMany)»
        «setterMethod(name, type, isMany, nullable, useHint, init, customImpl)»
    '''

    def getterMethod(Object it, String name, String type, Boolean isMany) '''
        /**
         * Returns the «name.formatForDisplay».
         *
         * @return «IF type == 'smallint' || type == 'bigint'»integer«ELSEIF type == 'datetime'»\DateTimeInterface«ELSE»«type»«ENDIF»«IF type.toLowerCase != 'array' && isMany»[]«ENDIF»
         */
        public function get«name.formatForCodeCapital»()
        {
            return $this->«name»;
        }
        «/* this last line is on purpose */»
    '''

    def setterMethod(Object it, String name, String type, Boolean isMany, Boolean nullable, Boolean useHint, String init, CharSequence customImpl) '''
        /**
         * Sets the «name.formatForDisplay».
         *
         * @param «IF type == 'smallint' || type == 'bigint'»integer«ELSEIF type == 'datetime'»\DateTimeInterface«ELSE»«type»«ENDIF»«IF type.toLowerCase != 'array' && isMany»[]«ENDIF» $«name»
         *
         * @return void
         */
        public function set«name.formatForCodeCapital»(«IF !nullable && useHint»«type» «ENDIF»$«name»«IF !init.empty» = «init»«ENDIF»)
        {
            «IF null !== customImpl && customImpl != ''»
                «customImpl»
            «ELSE»
                «setterMethodImpl(name, type, nullable)»
            «ENDIF»
        }
        «/* this last line is on purpose */»
    '''

    def private dispatch setterMethodImpl(Object it, String name, String type, Boolean nullable) '''
        «IF type == 'float'»
            «IF #['latitude', 'longitude'].contains(name)»
                $«name» = round(floatval($«name»), 7);
            «ENDIF»
            if (floatval($this->«name») !== floatval($«name»)) {
                «IF nullable»
                    $this->«name» = floatval($«name»);
                «ELSE»
                    $this->«name» = isset($«name») ? floatval($«name») : 0.00;
                «ENDIF»
            }
        «ELSE»
            if ($this->«name» != $«name») {
                «IF nullable»
                    $this->«name» = $«name»;
                «ELSE»
                    $this->«name» = isset($«name») ? $«name» : '';
                «ENDIF»
            }
        «ENDIF»
    '''

    def triggerPropertyChangeListeners(DerivedField it, String name) '''
        «IF null !== entity && ((entity instanceof Entity && (entity as Entity).hasNotifyPolicy) || entity.getInheritingEntities.exists[hasNotifyPolicy])»
            $this->_onPropertyChanged('«name.formatForCode»', $this->«name.formatForCode», $«name»);
        «ENDIF»
    '''

    def private dispatch setterMethodImpl(DerivedField it, String name, String type, Boolean nullable) '''
        «IF it instanceof NumberField»
            $«name» = round(floatval($«name»), «scale»);
        «ENDIF»
        if ($this->«name.formatForCode» !== $«name») {
            «triggerPropertyChangeListeners(name)»
            «setterAssignment(name)»
        }
    '''

    def private dispatch setterMethodImpl(BooleanField it, String name, String type, Boolean nullable) '''
        if (boolval($this->«name.formatForCode») !== boolval($«name»)) {
            «triggerPropertyChangeListeners(name)»
            «setterAssignment(name)»
        }
    '''

    def private dispatch setterAssignment(DerivedField it, String name) '''
        «IF nullable»
            $this->«name» = $«name»;
        «ELSE»
            $this->«name» = isset($«name») ? $«name» : '';
        «ENDIF»
    '''

    def private dispatch setterAssignment(BooleanField it, String name) '''
        $this->«name» = boolval($«name»);
    '''

    def private setterAssignmentNumeric(DerivedField it, String name) '''
        «val aggregators = getAggregatingRelationships»
        «IF !aggregators.empty»
            $diff = abs($this->«name» - $«name»);
        «ENDIF»
        $this->«name» = «numericCast('$' + name)»;
        «IF !aggregators.empty»
            «FOR aggregator : aggregators»
            $this->«aggregator.sourceAlias.formatForCode»->add«name.formatForCodeCapital»Without«entity.name.formatForCodeCapital»($diff);
            «ENDFOR»
        «ENDIF»
    '''

    def private dispatch setterMethodImpl(IntegerField it, String name, String type, Boolean nullable) '''
        if («numericCast('$this->' + name.formatForCode)» !== «numericCast('$' + name)») {
            «triggerPropertyChangeListeners(name)»
            «setterAssignmentNumeric(name)»
        }
    '''
    def private dispatch setterMethodImpl(NumberField it, String name, String type, Boolean nullable) '''
        if («numericCast('$this->' + name.formatForCode)» !== «numericCast('$' + name)») {
            «triggerPropertyChangeListeners(name)»
            «setterAssignmentNumeric(name)»
        }
    '''

    def private numericCast(DerivedField it, String variable) {
        if (notOnlyNumericInteger) {
            return variable
        } else {
            if (it instanceof AbstractIntegerField) {
                return 'intval(' + variable + ')'
            } else {
                return 'floatval(' + variable + ')'
            }
        }
    }

    def private dispatch setterAssignment(DatetimeField it, String name) '''
        if (!(null == $«name» && empty($«name»)) && !(is_object($«name») && $«name» instanceOf \DateTimeInterface)) {
            $«name» = new \DateTime«IF immutable»Immutable«ENDIF»($«name»);
        }
        «IF !nullable»

            if (null === $«name» || empty($«name»)) {
                $«name» = new \DateTime«IF immutable»Immutable«ENDIF»();
            }
        «ENDIF»

        if ($this->«name» != $«name») {
            $this->«name» = $«name»;
        }
    '''
}
