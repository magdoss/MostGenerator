package org.zikula.modulestudio.generator.cartridges.zclassic.models.entity.extensions

import de.guite.modulestudio.metamodel.AbstractIntegerField
import de.guite.modulestudio.metamodel.DerivedField
import de.guite.modulestudio.metamodel.Entity
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions

class Translatable extends AbstractExtension implements EntityExtensionInterface {

    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions

    /**
     * Generates additional annotations on class level.
     */
    override classAnnotations(Entity it) '''
         * @Gedmo\TranslationEntity(class="«entityClassName('translation', false)»")
    '''

    /**
     * Additional field annotations.
     */
    override columnAnnotations(DerivedField it) '''
        «IF translatable» * @Gedmo\Translatable
        «ENDIF»
    '''

    /**
     * Generates additional entity properties.
     */
    override properties(Entity it) '''

        /**
         * Used locale to override Translation listener's locale.
         * This is not a mapped field of entity metadata, just a simple property.
         *
         * @Assert\Locale()
         * @Gedmo\Locale«/*the same as @Gedmo\Language*/»
         * @var string $locale
         */
        protected $locale;
    '''

    /**
     * Generates additional accessor methods.
     */
    override accessors(Entity it) '''
        «(new FileHelper(application)).getterAndSetterMethods(it, 'locale', 'string', false, true, false, '', '')»
    '''

    /**
     * Returns the extension class type.
     */
    override extensionClassType(Entity it) {
        'translation'
    }

    /**
     * Returns the extension class import statements.
     */
    override extensionClassImports(Entity it) '''
        «IF primaryKey instanceof AbstractIntegerField»
            use Doctrine\ORM\Mapping as ORM;
        «ENDIF»
        use Gedmo\Translatable\Entity\MappedSuperclass\«extensionBaseClass»;
    '''

    /**
     * Returns the extension base class.
     */
    override extensionBaseClass(Entity it) {
        'AbstractTranslation'
    }

    /**
     * Returns the extension class description.
     */
    override extensionClassDescription(Entity it) {
        'Entity extension domain class storing ' + name.formatForDisplay + ' translations.'
    }

    /**
     * Returns the extension base class implementation.
     */
    override extensionClassBaseImplementation(Entity it) '''
        «IF primaryKey instanceof AbstractIntegerField»
            /**
             * Use integer instead of string for increased performance.
             * @see https://github.com/Atlantic18/DoctrineExtensions/issues/1512
             *
             * @var integer $foreignKey
             *
             * @ORM\Column(name="foreign_key", type="integer")
             */
            protected $foreignKey;

        «ENDIF»
        /**
         * Clone interceptor implementation.
         * Performs a quite simple shallow copy.
         *
         * See also:
         * (1) http://docs.doctrine-project.org/en/latest/cookbook/implementing-wakeup-or-clone.html
         * (2) http://www.php.net/manual/en/language.oop5.cloning.php
         * (3) http://stackoverflow.com/questions/185934/how-do-i-create-a-copy-of-an-object-in-php
         */
        public function __clone()
        {
            // if the entity has no identity do nothing, do NOT throw an exception
            if (!$this->id) {
                return;
            }

            // unset identifier
            $this->id = 0;
        }
    '''

    /**
     * Returns the extension implementation class ORM annotations.
     */
    override extensionClassImplAnnotations(Entity it) '''
         «' '»*
         «' '»* @ORM\Entity(repositoryClass="«repositoryClass(extensionClassType)»")
         «' '»* @ORM\Table(
         «' '»*     name="«fullEntityTableName»_translation",
         «' '»*     options={"row_format":"DYNAMIC"},
         «' '»*     indexes={
         «' '»*         @ORM\Index(name="translations_lookup_idx", columns={
         «' '»*             "locale", "object_class", "foreign_key"
         «' '»*         })
         «' '»*     },
         «' '»*     uniqueConstraints={
         «' '»*         @ORM\UniqueConstraint(name="lookup_unique_idx", columns={
         «' '»*             "locale", "object_class", "field", "foreign_key"
         «' '»*         })
         «' '»*     }
         «' '»* )
    '''
}
