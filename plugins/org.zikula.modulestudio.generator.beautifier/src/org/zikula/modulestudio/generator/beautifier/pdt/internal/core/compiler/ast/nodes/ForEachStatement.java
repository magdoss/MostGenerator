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

import org.eclipse.dltk.ast.ASTVisitor;
import org.eclipse.dltk.ast.expressions.Expression;
import org.eclipse.dltk.ast.statements.Statement;
import org.eclipse.dltk.utils.CorePrinter;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.compiler.ast.visitor.ASTPrintVisitor;

/**
 * Represents a for each statement
 * 
 * <pre>e.g.
 * 
 * <pre>
 * foreach (array_expression as $value)
 *   statement;
 * 
 * foreach (array_expression as $key => $value)
 *   statement;
 * 
 * foreach (array_expression as $key => $value):
 *   statement;
 *   ...
 * endforeach;
 */
public class ForEachStatement extends Statement {

    private final Expression expression;
    private final Expression key;
    private final Expression value;
    private final Statement statement;

    public ForEachStatement(int start, int end, Expression expression,
            Expression key, Expression value, Statement statement) {
        super(start, end);

        assert expression != null && value != null && statement != null;
        this.expression = expression;
        this.key = key;
        this.value = value;
        this.statement = statement;
    }

    public ForEachStatement(int start, int end, Expression expression,
            Expression value, Statement statement) {
        this(start, end, expression, null, value, statement);
    }

    @Override
    public void traverse(ASTVisitor visitor) throws Exception {
        final boolean visit = visitor.visit(this);
        if (visit) {
            expression.traverse(visitor);
            if (key != null) {
                key.traverse(visitor);
            }
            value.traverse(visitor);
            statement.traverse(visitor);
        }
        visitor.endvisit(this);
    }

    @Override
    public int getKind() {
        return ASTNodeKinds.FOR_EACH_STATEMENT;
    }

    public Expression getExpression() {
        return expression;
    }

    public Expression getKey() {
        return key;
    }

    public Statement getStatement() {
        return statement;
    }

    public Expression getValue() {
        return value;
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
