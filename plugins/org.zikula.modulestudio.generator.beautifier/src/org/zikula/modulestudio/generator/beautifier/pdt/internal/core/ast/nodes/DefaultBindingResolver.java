package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes;

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
 * Based on package
 * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes;
 * 
 *******************************************************************************/

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.core.runtime.Assert;
import org.eclipse.dltk.core.DLTKCore;
import org.eclipse.dltk.core.IField;
import org.eclipse.dltk.core.IMember;
import org.eclipse.dltk.core.IMethod;
import org.eclipse.dltk.core.IModelElement;
import org.eclipse.dltk.core.ISourceModule;
import org.eclipse.dltk.core.IType;
import org.eclipse.dltk.core.ModelException;
import org.eclipse.dltk.core.WorkingCopyOwner;
import org.eclipse.dltk.ti.types.IEvaluatedType;
import org.zikula.modulestudio.generator.beautifier.GeneratorBeautifierPlugin;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.visitor.AbstractVisitor;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.model.PerFileModelAccessCache;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.typeinference.BindingUtility;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.typeinference.IModelAccessCache;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.typeinference.PHPClassType;

/**
 * @author Roy, 2008 TODO : caching is a must have for this resolver
 */
public class DefaultBindingResolver extends BindingResolver {

    /*
     * Holds on binding tables that can be shared by several ASTs.
     */
    protected static class BindingTables {

        /**
         * This map is used to get a binding from its binding key.
         */
        Map<String, IBinding> bindingKeysToBindings;

        /**
         * This map is used to keep the correspondence between new ast nodes and
         * the compiler nodes
         */
        Map<Integer, org.eclipse.dltk.ast.ASTNode> compilerNodeToASTNode;

        BindingTables() {
            this.compilerNodeToASTNode = new HashMap<Integer, org.eclipse.dltk.ast.ASTNode>();
            this.bindingKeysToBindings = new HashMap<String, IBinding>();
        }

    }

    /**
     * The shared binding tables accros ASTs.
     */
    BindingTables bindingTables;

    /**
     * Shared source module for this binding resolver, used when resolving types
     */
    private final ISourceModule sourceModule;

    /**
     * The working copy owner that defines the context in which this resolver is
     * creating the bindings.
     */
    WorkingCopyOwner workingCopyOwner;

    /**
     * Used to resolve types of expressions
     */
    private final BindingUtility bindingUtil;

    /**
     * Model access cache
     */
    private final PerFileModelAccessCache modelAccessCache;

    /**
     * @param sourceModule
     *            of this resolver
     */
    public DefaultBindingResolver(ISourceModule sourceModule,
            WorkingCopyOwner owner) {
        this.sourceModule = sourceModule;
        this.workingCopyOwner = owner;
        this.bindingUtil = new BindingUtility(this.sourceModule);
        this.bindingTables = new BindingTables();
        this.modelAccessCache = new PerFileModelAccessCache(sourceModule);
    }

    private ITypeBinding internalGetTypeBinding(IEvaluatedType type,
            IModelElement modelElement) {
        final String typeName = type.getTypeName();
        if (typeName == null) {
            return null;
        }
        final String key = IModelElement.TYPE + ":" + typeName;
        IBinding binding = bindingTables.bindingKeysToBindings.get(key);
        if (binding == null) {
            binding = new TypeBinding(this, type, modelElement);
            bindingTables.bindingKeysToBindings.put(key, binding);
        }
        return (ITypeBinding) binding;
    }

    private ITypeBinding internalGetTypeBinding(IEvaluatedType type,
            IModelElement[] modelElements) {
        final String typeName = type.getTypeName();
        if (typeName == null) {
            return null;
        }
        final String key = IModelElement.TYPE + ":" + typeName;
        IBinding binding = bindingTables.bindingKeysToBindings.get(key);
        if (binding == null) {
            binding = new TypeBinding(this, type, modelElements);
            bindingTables.bindingKeysToBindings.put(key, binding);
        }
        return (ITypeBinding) binding;
    }

    /**
     * Returns the new type binding corresponding to the given type.
     * 
     * <p>
     * The default implementation of this method returns <code>null</code>.
     * Subclasses may reimplement.
     * </p>
     * 
     * @param type
     *            the given type
     * @return the new type binding
     */
    @Override
    ITypeBinding getTypeBinding(IType type) {
        if (type != null) {
            return internalGetTypeBinding(PHPClassType.fromIType(type), type);
        }
        return null;
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#getTypeBinding (org.eclipse.dltk.core.IType[])
     */
    @Override
    ITypeBinding getTypeBinding(IType[] types) {
        if (types != null && types.length > 0) {
            return internalGetTypeBinding(PHPClassType.fromIType(types[0]),
                    types);
        }
        return null;
    }

    /**
     * Returns the new variable binding corresponding to the given old variable
     * binding.
     * 
     * @param field
     *            An {@link IField}
     * @return the new variable binding, or null in case the given field is
     *         null.
     */
    @Override
    IVariableBinding getVariableBinding(IField field) {
        if (field != null) {
            // Cache?
            return new VariableBinding(this, field);
        }
        return null;
    }

    /**
     * Returns the new method binding corresponding to the given {@link IMethod}
     * .
     * 
     * @param method
     *            An {@link IMethod}
     * @return the new method binding
     */
    @Override
    public IMethodBinding getMethodBinding(IMethod method) {
        if (method != null) {
            // Cache?
            return new MethodBinding(this, method);
        }
        return null;
    }

    /**
     * Returns the {@link IEvaluatedType} according to the offset and the
     * length.
     */
    @Override
    protected IEvaluatedType getEvaluatedType(int offset, int length) {
        try {
            return bindingUtil.getType(offset, length);
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }
    }

    /**
     * Returns an {@link IModelElement} array according to the offset and the
     * length. The result is filtered using the 'File-Network'.
     * 
     * @param offset
     * @param length
     * 
     * @see #getModelElements(int, int, boolean)
     * @see BindingUtility#getModelElement(int, int)
     */
    @Override
    public IModelElement[] getModelElements(int offset, int length) {
        return getModelElements(offset, length, true);
    }

    /**
     * Returns an {@link IModelElement} array according to the offset and the
     * length. Use the filter flag to indicate whether the 'File-Network' should
     * be used to filter the results.
     * 
     * @param offset
     * @param length
     * @param filter
     *            Indicate whether to use the File-Network in order to filter
     *            the results.
     * 
     * @see #getModelElements(int, int)
     * @see BindingUtility#getModelElement(int, int, boolean)
     */
    @Override
    public IModelElement[] getModelElements(int offset, int length,
            boolean filter) {
        try {
            return bindingUtil.getModelElement(offset, length, filter,
                    getModelAccessCache());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveName(org
     * .eclipse.php.internal.core.ast.nodes.Identifier)
     */
    @Override
    IBinding resolveName(Identifier name) {
        // workaround for bug 253193's "ctrl+T not functional on methods"
        final FunctionName functionName = getFunctionName(name);
        if (functionName != null
                && functionName.getParent() instanceof FunctionInvocation) {
            return resolveFunction((FunctionInvocation) functionName
                    .getParent());
        }
        // end
        if (name.getParent() instanceof Variable) {
            return resolveVariable((Variable) name.getParent());
        }
        return resolveExpressionType(name);
    }

    private FunctionName getFunctionName(Identifier name) {
        ASTNode node = name.getParent();
        while (node != null) {
            if (node instanceof FunctionName) {
                return (FunctionName) node;
            }
            node = node.getParent();
        }
        return null;
    }

    /**
     * Resolves the given method declaration and returns the binding for it.
     * <p>
     * The implementation of <code>MethodDeclaration.resolveBinding</code>
     * forwards to this method. How the method resolves is often a function of
     * the context in which the method declaration node is embedded as well as
     * the method declaration subtree itself.
     * </p>
     * <p>
     * The default implementation of this method returns <code>null</code>.
     * Subclasses may reimplement.
     * </p>
     * 
     * @param method
     *            the method or constructor declaration of interest
     * @return the binding for the given method declaration, or
     *         <code>null</code> if no binding is available
     */
    @Override
    IMethodBinding resolveMethod(MethodDeclaration method) {
        if (method == null || method.getFunction() == null) {
            throw new IllegalArgumentException(
                    "Can not resolve null expression");
        }

        try {
            final IModelElement elementAt = sourceModule.getElementAt(method
                    .getStart());
            if (elementAt instanceof IMethod) {
                return getMethodBinding((IMethod) elementAt);
            }

        } catch (final ModelException e) {
            if (DLTKCore.DEBUG) {
                e.printStackTrace();
            }
        }
        return null;
    }

    /**
     * Returns the resolved type of the given expression. The results are NOT
     * filtered by the File-Network.
     * 
     * @return the resolved type of the given expression, null if can't
     *         evaluate.
     */
    @Override
    ITypeBinding resolveExpressionType(Expression expression) {
        if (expression == null) {
            throw new IllegalArgumentException(
                    "Can not resolve null expression");
        }
        final int start = expression.getStart();
        final int length = expression.getLength();
        final IEvaluatedType type = getEvaluatedType(start, length);
        if (type != null) {
            final IModelElement[] modelElements = getModelElements(start,
                    length, false);
            return internalGetTypeBinding(type, modelElements);
        }
        return null;
    }

    /*
     * (non-Javadoc)
     * @see BindingResolver#resolveInclude(Include)
     */
    @Override
    IBinding resolveInclude(Include includeDeclaration) {
        return new IncludeBinding(sourceModule, includeDeclaration);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#findDeclaringNode
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.IBinding)
     */
    @Override
    org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ASTNode findDeclaringNode(
            IBinding binding) {
        // TODO Auto-generated method stub
        return super.findDeclaringNode(binding);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#findDeclaringNode (java.lang.String)
     */
    @Override
    org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ASTNode findDeclaringNode(
            String bindingKey) {
        // TODO Auto-generated method stub
        return super.findDeclaringNode(bindingKey);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#getTypeBinding
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.FieldsDeclaration)
     */
    @Override
    ITypeBinding getTypeBinding(SingleFieldDeclaration fieldDeclaration) {
        IModelElement[] modelElements;
        try {
            modelElements = this.bindingUtil.getModelElement(
                    fieldDeclaration.getStart(), fieldDeclaration.getLength(),
                    getModelAccessCache());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }

        if (modelElements != null && modelElements.length > 0) {
            if (modelElements[0].getElementType() == IModelElement.TYPE) {
                final List<IType> types = new ArrayList<IType>(
                        modelElements.length);
                for (final IModelElement elem : modelElements) {
                    types.add((IType) elem);
                }
                return getTypeBinding(types.toArray(new IType[types.size()]));
            }
        }
        return super.getTypeBinding(fieldDeclaration);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#getTypeBinding
     * (org.eclipse.dltk.ti.types.IEvaluatedType)
     */
    @Override
    ITypeBinding getTypeBinding(IEvaluatedType referenceBinding,
            ISourceModule sourceModule) {
        if (referenceBinding != null) {
            return internalGetTypeBinding(referenceBinding, sourceModule);
        }
        return null;
    }

    /*
     * (non-Javadoc)
     * @seeorg.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver# resolveConstantExpressionValue
     * (org.zikula.modulestudio.
     * generator.beautifier.pdt.internal.core.ast.nodes.Expression)
     */
    @Override
    Object resolveConstantExpressionValue(Expression expression) {
        // TODO Auto-generated method stub
        return super.resolveConstantExpressionValue(expression);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveConstructor
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.ClassInstanceCreation)
     */
    @Override
    IMethodBinding resolveConstructor(ClassInstanceCreation expression) {
        IModelElement[] modelElements;
        try {
            modelElements = sourceModule.codeSelect(expression.getStart(),
                    expression.getLength());
        } catch (final ModelException e) {
            // Logger.log(IStatus.ERROR, e.toString());
            GeneratorBeautifierPlugin.log(e);
            return null;
        }

        if (modelElements != null && modelElements.length > 0) {
            for (final IModelElement element : modelElements) {
                if (element.getElementType() == IModelElement.METHOD) {
                    return new MethodBinding(this, (IMethod) element);
                }
            }
        }
        return super.resolveConstructor(expression);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveConstructor
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.MethodInvocation)
     */
    @Override
    IMethodBinding resolveConstructor(MethodInvocation expression) {
        final IMethodBinding binding = resolveMethod(expression);
        if (binding != null) {
            return binding;
        }
        return super.resolveConstructor(expression);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveField(
     * org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.FieldAccess)
     */
    @Override
    IVariableBinding resolveField(FieldAccess fieldAccess) {
        final VariableBase member = fieldAccess.getMember();
        if (member.getType() == ASTNode.VARIABLE) {
            final Variable var = (Variable) member;
            if (!var.isDollared() && var.getName() instanceof Identifier) {
                final Identifier id = (Identifier) var.getName();
                final String fieldName = "$" + id.getName();
                final ITypeBinding type = fieldAccess.getDispatcher()
                        .resolveTypeBinding();
                return Bindings.findFieldInHierarchy(type, fieldName);
            }
        }
        return null;
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveField(
     * org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.StaticConstantAccess)
     */
    @Override
    IVariableBinding resolveField(StaticConstantAccess constantAccess) {
        final Identifier constName = constantAccess.getConstant();
        final ITypeBinding type = constantAccess.getClassName()
                .resolveTypeBinding();
        return Bindings.findFieldInHierarchy(type, constName.getName());
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveField(
     * org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.StaticFieldAccess)
     */
    @Override
    IVariableBinding resolveField(StaticFieldAccess fieldAccess) {
        final VariableBase member = fieldAccess.getField();
        if (member.getType() == ASTNode.VARIABLE) {
            final Variable var = (Variable) member;
            if (var.isDollared() && var.getName() instanceof Identifier) {
                final Identifier id = (Identifier) var.getName();
                final String fieldName = "$" + id.getName();
                final ITypeBinding type = fieldAccess.getClassName()
                        .resolveTypeBinding();
                return Bindings.findFieldInHierarchy(type, fieldName);
            }
        }
        return null;
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveFunction
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.FunctionDeclaration)
     */
    @Override
    IFunctionBinding resolveFunction(FunctionDeclaration function) {
        IModelElement[] modelElements = null;
        try {
            final Identifier functionName = function.getFunctionName();
            modelElements = sourceModule.codeSelect(functionName.getStart(),
                    functionName.getLength());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }
        if (modelElements != null && modelElements.length > 0) {
            for (final IModelElement element : modelElements) {
                if (element.getElementType() == IModelElement.METHOD) {
                    return new MethodBinding(this, (IMethod) element);
                }
            }
        }
        return super.resolveFunction(function);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveFunction
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.FunctionInvocation)
     */
    @Override
    IFunctionBinding resolveFunction(FunctionInvocation function) {
        IModelElement[] modelElements = null;
        try {
            final FunctionName functionName = function.getFunctionName();
            modelElements = sourceModule.codeSelect(functionName.getStart(),
                    functionName.getLength());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }
        if (modelElements != null && modelElements.length > 0) {
            for (final IModelElement element : modelElements) {
                if (element.getElementType() == IModelElement.METHOD) {
                    return new MethodBinding(this, (IMethod) element);
                }
            }
        }
        return super.resolveFunction(function);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveMethod
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.MethodInvocation)
     */
    @Override
    IMethodBinding resolveMethod(MethodInvocation method) {
        IModelElement[] modelElements = null;
        try {
            final FunctionName functionName = method.getMethod()
                    .getFunctionName();
            modelElements = sourceModule.codeSelect(functionName.getStart(),
                    functionName.getLength());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }
        if (modelElements != null && modelElements.length > 0) {
            for (final IModelElement element : modelElements) {
                if (element.getElementType() == IModelElement.METHOD) {
                    return new MethodBinding(this, (IMethod) element);
                }
            }
        }
        return super.resolveMethod(method);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveMethod
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.StaticMethodInvocation)
     */
    @Override
    IMethodBinding resolveMethod(StaticMethodInvocation method) {
        IModelElement[] modelElements = null;
        try {
            final FunctionName functionName = method.getMethod()
                    .getFunctionName();
            modelElements = sourceModule.codeSelect(functionName.getStart(),
                    functionName.getLength());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }
        if (modelElements != null && modelElements.length > 0) {
            for (final IModelElement element : modelElements) {
                if (element.getElementType() == IModelElement.METHOD) {
                    return new MethodBinding(this, (IMethod) element);
                }
            }
        }
        return super.resolveMethod(method);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveType(org
     * .eclipse.php.internal.core.ast.nodes.TypeDeclaration)
     */
    @Override
    ITypeBinding resolveType(TypeDeclaration type) {

        IModelElement[] modelElements;
        try {
            modelElements = this.bindingUtil.getModelElement(type.getName()
                    .getStart(), type.getName().getLength(),
                    getModelAccessCache());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
            return null;
        }

        if (modelElements != null && modelElements.length > 0) {
            if (modelElements[0].getElementType() == IModelElement.TYPE) {
                final List<IType> types = new ArrayList<IType>(
                        modelElements.length);
                for (final IModelElement elem : modelElements) {
                    types.add((IType) elem);
                }
                return getTypeBinding(types.toArray(new IType[types.size()]));
            }
        }
        return super.resolveType(type);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveTypeParameter
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.FormalParameter)
     */
    @Override
    ITypeBinding resolveTypeParameter(FormalParameter typeParameter) {
        // TODO Auto-generated method stub
        return super.resolveTypeParameter(typeParameter);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveVariable
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.FieldsDeclaration)
     */
    @Override
    IVariableBinding resolveVariable(FieldsDeclaration variable) {
        // TODO Auto-generated method stub
        return super.resolveVariable(variable);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveVariable
     * (org.zikula.modulestudio.generator.beautifier
     * .pdt.internal.core.ast.nodes.Variable)
     */
    @Override
    IVariableBinding resolveVariable(Variable variable) {
        IModelElement modelElements = null;
        try {
            modelElements = bindingUtil.getFieldByPosition(variable.getStart(),
                    variable.getLength());
        } catch (final ModelException e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
        } catch (final Exception e) {
            GeneratorBeautifierPlugin.log(e);
            // Logger.log(IStatus.ERROR, e.toString());
        }

        if (modelElements != null) {
            if (modelElements.getElementType() == IModelElement.FIELD) {
                final int id = LocalVariableIndex.perform(
                        variable.getEnclosingBodyNode(), variable);
                return new VariableBinding(this, (IMember) modelElements,
                        variable, id);
            }

        }
        return super.resolveVariable(variable);
    }

    /*
     * (non-Javadoc)
     * @see
     * org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes
     * .BindingResolver#resolveWellKnownType (java.lang.String)
     */
    @Override
    ITypeBinding resolveWellKnownType(String name) {
        // TODO Auto-generated method stub
        return super.resolveWellKnownType(name);
    }

    private static class LocalVariableIndex extends AbstractVisitor {

        private int fTopIndex;
        // in case we are in the program scope
        // we don't want to descend into function/class/interface scope
        private static boolean isProgramScope = false;

        private final Set<String> variablesSet = new HashSet<String>();
        private final Variable variable;

        public LocalVariableIndex(Variable variable) {
            this.variable = variable;
        }

        /**
         * Computes the maximum number of local variable declarations in the
         * given body declaration.
         * 
         * @param node
         *            the body declaration. Must either be a method declaration
         *            or an initializer.
         * @return the maximum number of local variables
         */
        public static int perform(ASTNode node, Variable variable) {
            Assert.isTrue(node != null);

            switch (node.getType()) {
                case ASTNode.METHOD_DECLARATION:
                    isProgramScope = false;
                    return internalPerform(
                            ((MethodDeclaration) node).getFunction(), variable);
                case ASTNode.FUNCTION_DECLARATION:
                    isProgramScope = false;
                    return internalPerform(node, variable);
                case ASTNode.PROGRAM:
                    isProgramScope = true;
                    return internalPerform(node, variable);
                default:
                    Assert.isTrue(false);
            }
            return -1;
        }

        private static int internalPerform(ASTNode node, Variable variable) {
            final LocalVariableIndex counter = new LocalVariableIndex(variable);
            node.accept(counter);
            return counter.fTopIndex;
        }

        /**
         * Insert to the variables Name set each variable that is first
         * encountered in the flow
         */
        @Override
        public boolean visit(Variable variable) {
            final Expression name = variable.getName();
            if (variable.isDollared() && name instanceof Identifier) {
                final String variableName = ((Identifier) name).getName();
                if (!variableName.equalsIgnoreCase("this")
                        && !variablesSet.contains(variableName)) {
                    final String searchName = ((Identifier) this.variable
                            .getName()).getName();
                    if (variableName.equals(searchName)
                            && variable.getType() == this.variable.getType()) {
                        handleVariableBinding();
                    }

                    variablesSet.add(variableName);
                }
            }
            return true;

        }

        @Override
        public boolean visit(FunctionDeclaration function) {
            return !isProgramScope;
        }

        @Override
        public boolean visit(ClassDeclaration classDeclaration) {
            return !isProgramScope;
        }

        @Override
        public boolean visit(InterfaceDeclaration interfaceDeclaration) {
            return !isProgramScope;
        }

        private void handleVariableBinding() {
            fTopIndex = variablesSet.size();
        }
    }

    @Override
    public IModelAccessCache getModelAccessCache() {
        return modelAccessCache;
    }
}
