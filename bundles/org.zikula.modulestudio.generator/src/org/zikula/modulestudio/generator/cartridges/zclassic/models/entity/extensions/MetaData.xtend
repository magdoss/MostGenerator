package org.zikula.modulestudio.generator.cartridges.zclassic.models.entity.extensions

import de.guite.modulestudio.metamodel.DerivedField
import de.guite.modulestudio.metamodel.Entity
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class MetaData extends AbstractExtension implements EntityExtensionInterface {

    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    /**
     * Generates additional annotations on class level.
     */
    override classAnnotations(Entity it) '''
    '''

    /**
     * Additional field annotations.
     */
    override columnAnnotations(DerivedField it) '''
    '''

    /**
     * Generates additional entity properties.
     */
    override properties(Entity it) '''

        /**
         * @ORM\OneToOne(targetEntity="«IF !application.targets('1.3.x')»\«ENDIF»«entityClassName('metaData', false)»", 
         *               mappedBy="entity", cascade={"all"},
         *               orphanRemoval=true)
         * @var «IF !application.targets('1.3.x')»\«ENDIF»«entityClassName('metaData', false)»
         */
        protected $metadata = null;
    '''

    /**
     * Generates additional accessor methods.
     */
    override accessors(Entity it) '''
        «val fh = new FileHelper»
        «fh.getterAndSetterMethods(it, 'metadata', (if (!application.targets('1.3.x')) '\\' else '') + entityClassName('metaData', false), false, true, 'null', '')»
    '''

    /**
     * Returns the extension class type.
     */
    override extensionClassType(Entity it) {
        'metaData'
    }

    /**
     * Returns the extension class import statements.
     */
    override extensionClassImports(Entity it) '''
        use Doctrine\ORM\Mapping as ORM;
        «IF !application.targets('1.3.x')»
            use Zikula\Core\Doctrine\Entity\«extensionBaseClass»;
        «ENDIF»
    '''

    /**
     * Returns the extension base class.
     */
    override extensionBaseClass(Entity it) {
        if (!application.targets('1.3.x')) {
            'AbstractEntityMetadata'
        } else {
            'Zikula_Doctrine2_Entity_EntityMetadata'
        }
    }

    /**
     * Returns the extension class description.
     */
    override extensionClassDescription(Entity it) {
        'Entity extension domain class storing ' + name.formatForDisplay + ' meta data.'
    }

    /**
     * Returns the extension base class ORM annotations.
     */
    override extensionClassBaseAnnotations(Entity it) '''
        /**
         * @ORM\OneToOne(targetEntity="«IF !application.targets('1.3.x')»\«ENDIF»«entityClassName('', false)»", inversedBy="metadata")
         * @ORM\JoinColumn(name="entityId", referencedColumnName="«getPrimaryKeyFields.head.name.formatForCode»", unique=true)
         * @var «IF !application.targets('1.3.x')»\«ENDIF»«entityClassName('', false)»
         */
        protected $entity;

        «extensionClassEntityAccessors»
    '''

    /**
     * Returns the extension implementation class ORM annotations.
     */
    override extensionClassImplAnnotations(Entity it) '''
         «' '»* @ORM\Entity(repositoryClass="«IF !application.targets('1.3.x')»\«ENDIF»«repositoryClass(extensionClassType)»")
         «' '»* @ORM\Table(name="«fullEntityTableName»_metadata")
    '''
}