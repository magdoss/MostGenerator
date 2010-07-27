package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.rewrite;

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
 * Based on package org.eclipse.php.internal.core.ast.rewrite;
 * 
 *******************************************************************************/

import java.util.ArrayList;
import java.util.List;

import org.eclipse.text.edits.ISourceModifier;
import org.eclipse.text.edits.ReplaceEdit;

public class SourceModifier implements ISourceModifier {

    private final String destinationIndent;
    private final int sourceIndentLevel;
    private final int tabWidth;
    private final int indentWidth;

    public SourceModifier(int sourceIndentLevel, String destinationIndent,
            int tabWidth, int indentWidth) {
        this.destinationIndent = destinationIndent;
        this.sourceIndentLevel = sourceIndentLevel;
        this.tabWidth = tabWidth;
        this.indentWidth = indentWidth;
    }

    @Override
    public ISourceModifier copy() {
        // We are state less
        return this;
    }

    @Override
    public ReplaceEdit[] getModifications(String source) {
        final List result = new ArrayList();
        final int destIndentLevel = IndentManipulation.measureIndentUnits(
                this.destinationIndent, this.tabWidth, this.indentWidth);
        if (destIndentLevel == this.sourceIndentLevel) {
            return (ReplaceEdit[]) result
                    .toArray(new ReplaceEdit[result.size()]);
        }
        return IndentManipulation.getChangeIndentEdits(source,
                this.sourceIndentLevel, this.tabWidth, this.indentWidth,
                this.destinationIndent);
    }
}
