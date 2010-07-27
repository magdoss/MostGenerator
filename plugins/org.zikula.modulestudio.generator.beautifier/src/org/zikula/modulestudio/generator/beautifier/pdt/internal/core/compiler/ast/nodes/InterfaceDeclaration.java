package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.compiler.ast.nodes;

/*******************************************************************************
 * Copyright (c) 2009 IBM Corporation and others. All rights reserved. This
 * program and the accompanying materials are made available under the terms of
 * the Eclipse Public License v1.0 which accompanies this distribution, and is
 * available at http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors: IBM Corporation - initial API and implementation Zend
 * Technologies
 * 
 * 
 * 
 * Based on package org.eclipse.php.internal.core.compiler.ast.nodes;
 * 
 *******************************************************************************/

import java.util.List;

import org.eclipse.dltk.ast.ASTListNode;
import org.eclipse.dltk.ast.Modifiers;
import org.eclipse.dltk.ast.declarations.TypeDeclaration;
import org.eclipse.dltk.ast.references.TypeReference;
import org.eclipse.dltk.ast.statements.Block;
import org.eclipse.dltk.utils.CorePrinter;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.compiler.ast.visitor.ASTPrintVisitor;

/**
 * Represents an interface declaration
 * 
 * <pre>
 * 
 * <pre>e.g.
 * 
 * <pre>
 * interface MyInterface { },
 * interface MyInterface extends Interface1, Interface2 {
 *  const MY_CONSTANT = 3;
 *  public function myFunction($a);
 * }
 */
public class InterfaceDeclaration extends TypeDeclaration implements
        IPHPDocAwareDeclaration, IRecoverable {

    private final PHPDocBlock phpDoc;
    private boolean isRecovered;

    public InterfaceDeclaration(int start, int end, int nameStart, int nameEnd,
            String interfaceName, List<TypeReference> interfaces, Block body,
            PHPDocBlock phpDoc) {
        super(interfaceName, nameStart, nameEnd, start, end);

        this.phpDoc = phpDoc;

        final int nodesStart = body.sourceStart() - 1;
        final ASTListNode parentsList = new ASTListNode(nodesStart, nodesStart);
        for (final TypeReference intface : interfaces) {
            parentsList.addNode(intface);
            if (parentsList.sourceStart() > intface.sourceStart()) {
                parentsList.setStart(intface.sourceStart());
            }
        }

        if (parentsList.getChilds().size() > 0) {
            setSuperClasses(parentsList);
        }

        setBody(body);

        setModifier(Modifiers.AccInterface);
    }

    @Override
    public PHPDocBlock getPHPDoc() {
        return phpDoc;
    }

    @Override
    public int getKind() {
        return ASTNodeKinds.INTERFACE_DECLARATION;
    }

    @Override
    public boolean isRecovered() {
        return isRecovered;
    }

    @Override
    public void setRecovered(boolean isRecovered) {
        this.isRecovered = isRecovered;
    }

    /**
     * We don't print anything - we use {@link ASTPrintVisitor} instead
     */
    @Override
    public final void printNode(CorePrinter output) {
    }

    @Override
    public String toString() {
        return ASTPrintVisitor.toXMLString(this);
    }
}
