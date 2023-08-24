--
--  Copyright (C) 2022-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.String_Vectors;

package LSP.Structures.Unwrap is
   pragma Preelaborate;

   function foldingRange (X : TextDocumentClientCapabilities_Optional)
     return FoldingRangeClientCapabilities_Optional is
       (if X.Is_Set then X.Value.foldingRange else (Is_Set => False));

   function semanticTokens (X : TextDocumentClientCapabilities_Optional)
     return SemanticTokensClientCapabilities_Optional is
       (if X.Is_Set then X.Value.semanticTokens else (Is_Set => False));

   function tokenTypes (X : SemanticTokensClientCapabilities_Optional)
     return LSP.Structures.Virtual_String_Vector is
       (if X.Is_Set then X.Value.tokenTypes
        else VSS.String_Vectors.Empty_Virtual_String_Vector);

   function tokenModifiers (X : SemanticTokensClientCapabilities_Optional)
     return LSP.Structures.Virtual_String_Vector is
       (if X.Is_Set then X.Value.tokenModifiers
        else VSS.String_Vectors.Empty_Virtual_String_Vector);

   function lineFoldingOnly (X : FoldingRangeClientCapabilities_Optional)
     return Boolean_Optional is
       (if X.Is_Set then X.Value.lineFoldingOnly else (Is_Set => False));

   function completion (X : TextDocumentClientCapabilities_Optional)
     return CompletionClientCapabilities_Optional is
       (if X.Is_Set then X.Value.completion else (Is_Set => False));

   function completionItem (X : CompletionClientCapabilities_Optional)
     return completionItem_OfCompletionClientCapabilities_Optional is
       (if X.Is_Set then X.Value.completionItem else (Is_Set => False));

   function resolveSupport
     (X : completionItem_OfCompletionClientCapabilities_Optional)
       return resolveSupport_OfWorkspaceSymbolClientCapabilities_Optional is
         (if X.Is_Set then X.Value.resolveSupport else (Is_Set => False));

   function properties
     (X : resolveSupport_OfWorkspaceSymbolClientCapabilities_Optional)
       return LSP.Structures.Virtual_String_Vector is
         (if X.Is_Set then X.Value.properties
          else VSS.String_Vectors.Empty_Virtual_String_Vector);

   function workspaceEdit (X : WorkspaceClientCapabilities_Optional)
     return WorkspaceEditClientCapabilities_Optional is
     (if X.Is_Set then X.Value.workspaceEdit else (Is_Set => False));

   function documentChanges (X : WorkspaceEditClientCapabilities_Optional)
     return Boolean_Optional is
     (if X.Is_Set then X.Value.documentChanges else (Is_Set => False));

   function resourceOperations (X : WorkspaceEditClientCapabilities_Optional)
     return LSP.Structures.ResourceOperationKind_Set is
     (if X.Is_Set then X.Value.resourceOperations else (others => False));

end LSP.Structures.Unwrap;
