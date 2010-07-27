package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.match;

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
 * Based on package org.eclipse.php.internal.core.ast.match;
 * 
 *******************************************************************************/

import org.eclipse.core.runtime.Assert;
import org.zikula.modulestudio.generator.beautifier.pdt.internal.core.ast.nodes.ASTNode;

public class PHPASTMatcher extends ASTMatcher {

    public static boolean doNodesMatch(ASTNode one, ASTNode other) {
        Assert.isNotNull(one);
        Assert.isNotNull(other);

        return one.subtreeMatch(new PHPASTMatcher(), other);
    }
}
