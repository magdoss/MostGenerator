package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.visitor;

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
 * Based on package org.eclipse.php.internal.core.ast.visitor;
 * 
 *******************************************************************************/

import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ASTError;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ASTNode;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ArrayAccess;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ArrayCreation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ArrayElement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Assignment;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.BackTickExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Block;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.BodyDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.BreakStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.CastExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.CatchClause;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ClassDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ClassInstanceCreation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ClassName;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.CloneExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Comment;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ConditionalExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ConstantDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ContinueStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.DeclareStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Dispatch;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.DoStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.EchoStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.EmptyStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Expression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ExpressionStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.FieldAccess;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.FieldsDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ForEachStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ForStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.FormalParameter;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.FunctionDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.FunctionInvocation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.FunctionName;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.GlobalStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Identifier;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.IfStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.IgnoreError;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.InLineHtml;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Include;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.InfixExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.InstanceOfExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.InterfaceDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ListVariable;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.MethodDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.MethodInvocation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ParenthesisExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.PostfixExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.PrefixExpression;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Program;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Quote;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Reference;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ReflectionVariable;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ReturnStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Scalar;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.SingleFieldDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Statement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.StaticConstantAccess;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.StaticDispatch;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.StaticFieldAccess;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.StaticMethodInvocation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.StaticStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.SwitchCase;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.SwitchStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ThrowStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.TryStatement;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.TypeDeclaration;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.UnaryOperation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.Variable;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.VariableBase;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.WhileStatement;

/**
 * <p>
 * This class provides a convenient behaviour-only extension mechanism for the
 * ASTNode hierarchy. If you feel like you would like to add a method to the
 * ASTNode hierarchy (or a subtree of the hierarchy), and you want to have
 * different implementations of it at different points in the hierarchy, simply
 * create a HierarchicalASTVisitor representing the new method and all its
 * implementations, locating each implementation within the right visit(XX)
 * method. If you wanted to add a method implementation to abstract class Foo,
 * an ASTNode descendant, put your implementation in visit(Foo). This class will
 * provide appropriate dispatch, just as if the method implementations had been
 * added to the ASTNode hierarchy.
 * </p>
 * 
 * <p>
 * <b>Details:<b>
 * </p>
 * 
 * <p>
 * This class has a visit(XX node) method for every for every class (concrete or
 * abstract) XX in the ASTNode hierarchy. In this class' default implementations
 * of these methods, the method corresponding to a given ASTNode descendant
 * class will call (and return the return value of) the visit(YY) method for
 * it's superclass YY, with the exception of the visit(ASTNode) method which
 * simply returns true, since ASTNode doesn't have a superclass that is within
 * the ASTNode hierarchy.
 * </p>
 * 
 * <p>
 * Because of this organization, when visit(XX) methods are overridden in a
 * subclass, and the visitor is applied to a node, only the most specialized
 * overridden method implementation for the node's type will be called, unless
 * this most specialized method calls other visit methods (this is discouraged)
 * or, (preferably) calls super.visit(XX node), (the reference type of the
 * parameter must be XX) which will invoke this class' implementation of the
 * method, which will, in turn, invoke the visit(YY) method corresponding to the
 * superclass, YY.
 * </p>
 * 
 * <p>
 * Thus, the dispatching behaviour achieved when HierarchicalASTVisitors'
 * visit(XX) methods, corresponding to a particular concrete or abstract ASTNode
 * descendant class, are overridden is exactly analogous to the dispatching
 * behaviour obtained when method implementations are added to the same ASTNode
 * descendant classes.
 * </p>
 */
public class HierarchicalVisitor extends AbstractVisitor {

    /**
     * Abstract Nodes that we added to the abstract visitor
     */
    @Override
    public boolean visit(ASTNode node) {
        return true;
    }

    public boolean visit(Statement statement) {
        return visit((ASTNode) statement);
    }

    public boolean visit(Expression expression) {
        return visit((ASTNode) expression);
    }

    public boolean visit(TypeDeclaration typeDeclaration) {
        return visit((Statement) typeDeclaration);
    }

    public boolean visit(VariableBase variableBase) {
        return visit((Expression) variableBase);
    }

    public boolean visit(Dispatch dispatch) {
        return visit((VariableBase) dispatch);
    }

    public boolean visit(StaticDispatch staticDispatch) {
        return visit((VariableBase) staticDispatch);
    }

    public boolean visit(BodyDeclaration bodyDeclaration) {
        return visit((Statement) bodyDeclaration);
    }

    /**
     * Redirect to the hierarchical node
     */

    @Override
    public boolean visit(ArrayAccess arrayAccess) {
        return visit((Variable) arrayAccess);
    }

    @Override
    public boolean visit(ArrayCreation arrayCreation) {
        return visit((Expression) arrayCreation);
    }

    @Override
    public boolean visit(ArrayElement arrayElement) {
        return visit((ASTNode) arrayElement);
    }

    @Override
    public boolean visit(Assignment assignment) {
        return visit((Expression) assignment);
    }

    @Override
    public boolean visit(ASTError astError) {
        return visit((Statement) astError);
    }

    @Override
    public boolean visit(BackTickExpression backTickExpression) {
        return visit((Expression) backTickExpression);
    }

    @Override
    public boolean visit(Block block) {
        return visit((Statement) block);
    }

    @Override
    public boolean visit(BreakStatement breakStatement) {
        return visit((Statement) breakStatement);
    }

    @Override
    public boolean visit(CastExpression castExpression) {
        return visit((Expression) castExpression);
    }

    @Override
    public boolean visit(CatchClause catchClause) {
        return visit((Statement) catchClause);
    }

    @Override
    public boolean visit(ConstantDeclaration classConstantDeclaration) {
        return visit((Statement) classConstantDeclaration);
    }

    @Override
    public boolean visit(ClassDeclaration classDeclaration) {
        return visit((TypeDeclaration) classDeclaration);
    }

    @Override
    public boolean visit(ClassInstanceCreation classInstanceCreation) {
        return visit((Expression) classInstanceCreation);
    }

    @Override
    public boolean visit(ClassName className) {
        return visit((ASTNode) className);
    }

    @Override
    public boolean visit(CloneExpression cloneExpression) {
        return visit((Expression) cloneExpression);
    }

    @Override
    public boolean visit(Comment comment) {
        return visit((ASTNode) comment);
    }

    @Override
    public boolean visit(ConditionalExpression conditionalExpression) {
        return visit((Expression) conditionalExpression);
    }

    @Override
    public boolean visit(ContinueStatement continueStatement) {
        return visit((Statement) continueStatement);
    }

    @Override
    public boolean visit(DeclareStatement declareStatement) {
        return visit((Statement) declareStatement);
    }

    @Override
    public boolean visit(DoStatement doStatement) {
        return visit((Statement) doStatement);
    }

    @Override
    public boolean visit(EchoStatement echoStatement) {
        return visit((Statement) echoStatement);
    }

    @Override
    public boolean visit(EmptyStatement emptyStatement) {
        return visit((Statement) emptyStatement);
    }

    @Override
    public boolean visit(ExpressionStatement expressionStatement) {
        return visit((Statement) expressionStatement);
    }

    @Override
    public boolean visit(FieldAccess fieldAccess) {
        return visit((Dispatch) fieldAccess);
    }

    @Override
    public boolean visit(FieldsDeclaration fieldsDeclaration) {
        return visit((BodyDeclaration) fieldsDeclaration);
    }

    @Override
    public boolean visit(ForEachStatement forEachStatement) {
        return visit((Statement) forEachStatement);
    }

    @Override
    public boolean visit(FormalParameter formalParameter) {
        return visit((ASTNode) formalParameter);
    }

    @Override
    public boolean visit(ForStatement forStatement) {
        return visit((Statement) forStatement);
    }

    @Override
    public boolean visit(FunctionDeclaration functionDeclaration) {
        return visit((Statement) functionDeclaration);
    }

    @Override
    public boolean visit(FunctionInvocation functionInvocation) {
        return visit((VariableBase) functionInvocation);
    }

    @Override
    public boolean visit(FunctionName functionName) {
        return visit((ASTNode) functionName);
    }

    @Override
    public boolean visit(GlobalStatement globalStatement) {
        return visit((Statement) globalStatement);
    }

    @Override
    public boolean visit(Identifier identifier) {
        return visit((Expression) identifier);
    }

    @Override
    public boolean visit(IfStatement ifStatement) {
        return visit((Statement) ifStatement);
    }

    @Override
    public boolean visit(IgnoreError ignoreError) {
        return visit((Expression) ignoreError);
    }

    @Override
    public boolean visit(Include include) {
        return visit((Expression) include);
    }

    @Override
    public boolean visit(InfixExpression infixExpression) {
        return visit((Expression) infixExpression);
    }

    @Override
    public boolean visit(InLineHtml inLineHtml) {
        return visit((Statement) inLineHtml);
    }

    @Override
    public boolean visit(InstanceOfExpression instanceOfExpression) {
        return visit((Expression) instanceOfExpression);
    }

    @Override
    public boolean visit(InterfaceDeclaration interfaceDeclaration) {
        return visit((TypeDeclaration) interfaceDeclaration);
    }

    @Override
    public boolean visit(ListVariable listVariable) {
        return visit((VariableBase) listVariable);
    }

    @Override
    public boolean visit(MethodDeclaration methodDeclaration) {
        return visit((BodyDeclaration) methodDeclaration);
    }

    @Override
    public boolean visit(MethodInvocation methodInvocation) {
        return visit((Dispatch) methodInvocation);
    }

    @Override
    public boolean visit(ParenthesisExpression parenthesisExpression) {
        return visit((Expression) parenthesisExpression);

    }

    @Override
    public boolean visit(PostfixExpression postfixExpression) {
        return visit((Expression) postfixExpression);
    }

    @Override
    public boolean visit(PrefixExpression prefixExpression) {
        return visit((Expression) prefixExpression);
    }

    @Override
    public boolean visit(Program program) {
        return visit((ASTNode) program);
    }

    @Override
    public boolean visit(Quote quote) {
        return visit((Expression) quote);
    }

    @Override
    public boolean visit(Reference reference) {
        return visit((Expression) reference);
    }

    @Override
    public boolean visit(ReflectionVariable reflectionVariable) {
        return visit((Variable) reflectionVariable);
    }

    @Override
    public boolean visit(ReturnStatement returnStatement) {
        return visit((Statement) returnStatement);
    }

    @Override
    public boolean visit(Scalar scalar) {
        return visit((Expression) scalar);
    }

    @Override
    public boolean visit(SingleFieldDeclaration singleFieldDeclaration) {
        return visit((ASTNode) singleFieldDeclaration);
    }

    @Override
    public boolean visit(StaticConstantAccess classConstantAccess) {
        return visit((StaticDispatch) classConstantAccess);
    }

    @Override
    public boolean visit(StaticFieldAccess staticFieldAccess) {
        return visit((StaticDispatch) staticFieldAccess);
    }

    @Override
    public boolean visit(StaticMethodInvocation staticMethodInvocation) {
        return visit((StaticDispatch) staticMethodInvocation);
    }

    @Override
    public boolean visit(StaticStatement staticStatement) {
        return visit((Statement) staticStatement);
    }

    @Override
    public boolean visit(SwitchCase switchCase) {
        return visit((Statement) switchCase);
    }

    @Override
    public boolean visit(SwitchStatement switchStatement) {
        return visit((Statement) switchStatement);
    }

    @Override
    public boolean visit(ThrowStatement throwStatement) {
        return visit((Statement) throwStatement);
    }

    @Override
    public boolean visit(TryStatement tryStatement) {
        return visit((Statement) tryStatement);
    }

    @Override
    public boolean visit(UnaryOperation unaryOperation) {
        return visit((Expression) unaryOperation);
    }

    @Override
    public boolean visit(Variable variable) {
        return visit((VariableBase) variable);
    }

    @Override
    public boolean visit(WhileStatement whileStatement) {
        return visit((Statement) whileStatement);
    }

}
