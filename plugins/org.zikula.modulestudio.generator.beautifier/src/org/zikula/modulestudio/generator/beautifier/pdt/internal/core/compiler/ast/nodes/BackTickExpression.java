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

import java.util.Collection;
import java.util.List;

import org.eclipse.dltk.ast.ASTVisitor;
import org.eclipse.dltk.ast.expressions.Expression;
import org.eclipse.dltk.utils.CorePrinter;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.compiler.ast.visitor.ASTPrintVisitor;

/**
 * Represents back tick expression
 * 
 * <pre>e.g.
 * 
 * <pre>
 * `.\exec.sh`
 */
public class BackTickExpression extends Expression {

    private final List<? extends Expression> expressions;

    public BackTickExpression(int start, int end,
            List<? extends Expression> expressions) {
        super(start, end);

        assert expressions != null;
        this.expressions = expressions;
    }

    @Override
    public void traverse(ASTVisitor visitor) throws Exception {
        final boolean visit = visitor.visit(this);
        if (visit) {
            for (final Expression expression : expressions) {
                expression.traverse(visitor);
            }
        }
        visitor.endvisit(this);
    }

    @Override
    public int getKind() {
        return ASTNodeKinds.BACK_TICK_EXPRESSION;
    }

    public Collection<? extends Expression> getExpressions() {
        return expressions;
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
