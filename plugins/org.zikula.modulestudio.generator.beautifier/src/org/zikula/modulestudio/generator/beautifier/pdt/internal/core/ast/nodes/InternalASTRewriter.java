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
 * Based on package org.eclipse.php.internal.core.ast.nodes;
 * 
 *******************************************************************************/

import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import org.eclipse.jface.text.IDocument;
import org.eclipse.jface.text.TextUtilities;
import org.eclipse.text.edits.MultiTextEdit;
import org.eclipse.text.edits.TextEdit;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.ASTRewriteAnalyzer;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.LineInformation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.ListRewriteEvent;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.NodeInfoStore;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.NodeRewriteEvent;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.RewriteEventStore;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.RewriteEventStore.CopySourceInfo;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.RewriteEventStore.PropertyLocation;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite.TargetSourceRangeComputer;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.scanner.AstLexer;

/**
 * Internal class: not intended to be used by client. When AST modifications
 * recording is enabled, all changes are recorded by this class.
 */
class InternalASTRewrite extends NodeEventHandler {

    /** root node for the rewrite: Only nodes under this root are accepted */
    private final Program root;

    protected final RewriteEventStore eventStore;
    protected final NodeInfoStore nodeStore;
    protected final Hashtable clonedNodes;

    int cloneDepth = 0;
    private final AstLexer lexer;

    /**
     * Constructor
     * 
     * @param root
     *            root node of the recorded ast.
     */
    public InternalASTRewrite(Program root) {
        this.root = root;
        this.eventStore = new RewriteEventStore();
        this.nodeStore = new NodeInfoStore(root.getAST());
        this.clonedNodes = new Hashtable();
        this.lexer = root.getAST().lexer;
    }

    /**
     * Performs the rewrite: The rewrite events are translated to the
     * corresponding in text changes.
     * 
     * @param document
     *            Document which describes the code of the AST that is passed in
     *            in the constructor. This document is accessed read-only.
     * @param options
     *            options
     * @throws IllegalArgumentException
     *             if the rewrite fails
     * @return Returns the edit describing the text changes.
     */
    public TextEdit rewriteAST(IDocument document, Map options) {
        final TextEdit result = new MultiTextEdit();

        final Program rootNode = getRootNode();
        if (rootNode != null) {
            final TargetSourceRangeComputer xsrComputer = new TargetSourceRangeComputer() {
                /**
                 * This implementation of
                 * {@link TargetSourceRangeComputer#computeSourceRange(ASTNode)}
                 * is specialized to work in the case of internal AST rewriting,
                 * where the original AST has been modified from its original
                 * form. This means that one cannot trust that the root of the
                 * given node is the compilation unit.
                 */
                @Override
                public SourceRange computeSourceRange(ASTNode node) {
                    final int extendedStartPosition = rootNode
                            .getExtendedStartPosition(node);
                    final int extendedLength = rootNode.getExtendedLength(node);
                    return new SourceRange(extendedStartPosition,
                            extendedLength);
                }
            };
            final LineInformation lineInfo = LineInformation.create(document);
            final String lineDelim = TextUtilities
                    .getDefaultLineDelimiter(document);
            final List comments = rootNode.comments();

            final ASTRewriteAnalyzer visitor = new ASTRewriteAnalyzer(lexer,
                    document, lineInfo, lineDelim, result, this.eventStore,
                    this.nodeStore, comments, options, xsrComputer);
            rootNode.accept(visitor);
        }
        return result;
    }

    private void markAsMoveOrCopyTarget(ASTNode node, ASTNode newChild) {
        final ASTNode source = (ASTNode) this.clonedNodes.get(newChild);
        if (source != null) {
            if (this.cloneDepth == 0) {
                final PropertyLocation propertyLocation = this.eventStore
                        .getPropertyLocation(source, RewriteEventStore.ORIGINAL);
                final CopySourceInfo sourceInfo = this.eventStore
                        .markAsCopySource(propertyLocation.getParent(),
                                propertyLocation.getProperty(), source, false);
                this.nodeStore.markAsCopyTarget(newChild, sourceInfo);
            }
        }
        else if ((newChild.getFlags() & ASTNode.ORIGINAL) != 0) {
            final PropertyLocation propertyLocation = this.eventStore
                    .getPropertyLocation(newChild, RewriteEventStore.ORIGINAL);
            final CopySourceInfo sourceInfo = this.eventStore.markAsCopySource(
                    propertyLocation.getParent(),
                    propertyLocation.getProperty(), newChild, true);
            this.nodeStore.markAsCopyTarget(newChild, sourceInfo);
        }
    }

    private Program getRootNode() {
        return this.root;
    }

    @Override
    public String toString() {
        final StringBuffer buf = new StringBuffer();
        buf.append("Events:\n"); //$NON-NLS-1$
        buf.append(this.eventStore.toString());
        return buf.toString();
    }

    @Override
    void preValueChangeEvent(ASTNode node, SimplePropertyDescriptor property) {
        // force event creation
        this.getNodeEvent(node, property);
    }

    @Override
    void postValueChangeEvent(ASTNode node, SimplePropertyDescriptor property) {
        final NodeRewriteEvent event = this.getNodeEvent(node, property);
        event.setNewValue(node.getStructuralProperty(property));
    }

    @Override
    void preAddChildEvent(ASTNode node, ASTNode child,
            StructuralPropertyDescriptor property) {
        if (property.isChildProperty()) {
            final NodeRewriteEvent event = this.getNodeEvent(node, property);
            event.setNewValue(child);
            if (child != null) {
                this.markAsMoveOrCopyTarget(node, child);
            }
        }
        else if (property.isChildListProperty()) {
            // force event creation
            this.getListEvent(node, property);
        }
    }

    @Override
    void postAddChildEvent(ASTNode node, ASTNode child,
            StructuralPropertyDescriptor property) {
        if (property.isChildListProperty()) {

            final ListRewriteEvent event = this.getListEvent(node, property);
            final List list = (List) node.getStructuralProperty(property);
            final int i = list.indexOf(child);
            final int s = list.size();
            int index;
            if (i + 1 < s) {
                final ASTNode nextNode = (ASTNode) list.get(i + 1);
                index = event.getIndex(nextNode, ListRewriteEvent.NEW);
            }
            else {
                index = -1;
            }
            event.insert(child, index);
            if (child != null) {
                this.markAsMoveOrCopyTarget(node, child);
            }
        }
    }

    @Override
    void preRemoveChildEvent(ASTNode node, ASTNode child,
            StructuralPropertyDescriptor property) {
        if (property.isChildProperty()) {
            final NodeRewriteEvent event = getNodeEvent(node, property);
            event.setNewValue(null);
        }
        else if (property.isChildListProperty()) {
            final ListRewriteEvent event = this.getListEvent(node, property);
            final int i = event.getIndex(child, ListRewriteEvent.NEW);
            final NodeRewriteEvent nodeEvent = (NodeRewriteEvent) event
                    .getChildren()[i];
            if (nodeEvent.getOriginalValue() == null) {
                event.revertChange(nodeEvent);
            }
            else {
                nodeEvent.setNewValue(null);
            }
        }
    }

    @Override
    void preReplaceChildEvent(ASTNode node, ASTNode child, ASTNode newChild,
            StructuralPropertyDescriptor property) {
        if (property.isChildProperty()) {
            final NodeRewriteEvent event = getNodeEvent(node, property);
            event.setNewValue(newChild);
            if (newChild != null) {
                this.markAsMoveOrCopyTarget(node, newChild);
            }
        }
        else if (property.isChildListProperty()) {
            final ListRewriteEvent event = this.getListEvent(node, property);
            final int i = event.getIndex(child, ListRewriteEvent.NEW);
            final NodeRewriteEvent nodeEvent = (NodeRewriteEvent) event
                    .getChildren()[i];
            nodeEvent.setNewValue(newChild);
            if (newChild != null) {
                this.markAsMoveOrCopyTarget(node, newChild);
            }
        }
    }

    @Override
    void preCloneNodeEvent(ASTNode node) {
        this.cloneDepth++;
    }

    @Override
    void postCloneNodeEvent(ASTNode node, ASTNode clone) {
        if (node.ast == root.ast && clone.ast == root.ast) {
            if ((node.getFlags() & ASTNode.ORIGINAL) != 0) {
                this.clonedNodes.put(clone, node);
            }
            else {
                // node can be a cloned node
                final Object original = this.clonedNodes.get(node);
                if (original != null) {
                    this.clonedNodes.put(clone, original);
                }
            }
        }
        this.cloneDepth--;
    }

    private NodeRewriteEvent getNodeEvent(ASTNode node,
            StructuralPropertyDescriptor property) {
        return this.eventStore.getNodeEvent(node, property, true);
    }

    private ListRewriteEvent getListEvent(ASTNode node,
            StructuralPropertyDescriptor property) {
        return this.eventStore.getListEvent(node, property, true);
    }
}
