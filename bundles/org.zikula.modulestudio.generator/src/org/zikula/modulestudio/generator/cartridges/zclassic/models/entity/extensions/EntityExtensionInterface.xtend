package org.zikula.modulestudio.generator.cartridges.zclassic.models.entity.extensions

import de.guite.modulestudio.metamodel.DerivedField
import de.guite.modulestudio.metamodel.Entity
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess

interface EntityExtensionInterface {

    /**
     * Generates additional annotations on class level.
     */
    def CharSequence classAnnotations(Entity it)

    /**
     * Additional field annotations.
     */
    def CharSequence columnAnnotations(DerivedField it)

    /**
     * Generates additional entity properties.
     */
    def CharSequence properties(Entity it)

    /**
     * Generates additional accessor methods.
     */
    def CharSequence accessors(Entity it)

    /**
     * Generates separate extension classes.
     */
    def void extensionClasses(Entity it, IMostFileSystemAccess fsa)

    /**
     * Returns the extension class type.
     */
    def String extensionClassType(Entity it)

    /**
     * Returns the extension class import statements.
     */
    def String extensionClassImports(Entity it)

    /**
     * Returns the extension base class.
     */
    def String extensionBaseClass(Entity it)

    /**
     * Returns the extension class description.
     */
    def String extensionClassDescription(Entity it)

    /**
     * Returns the extension base class implementation.
     */
    def String extensionClassBaseImplementation(Entity it)

    /**
     * Returns the extension implementation class ORM annotations.
     */
    def String extensionClassImplAnnotations(Entity it)

    /**
     * Returns the extension repository base class implementation.
     */
    def String extensionRepositoryClassBaseImplementation(Entity it)
}
