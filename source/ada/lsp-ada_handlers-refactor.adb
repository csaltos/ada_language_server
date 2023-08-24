------------------------------------------------------------------------------
--                         Language Server Protocol                         --
--                                                                          --
--                     Copyright (C) 2018-2023, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with VSS.Strings.Conversions;

with LSP.Ada_Documents; use LSP.Ada_Documents;
with LSP.Enumerations;
with LSP.Structures;    use LSP.Structures;
with LSP.Utils;

package body LSP.Ada_Handlers.Refactor is

   function To_DocumentUri (X : String)
     return LSP.Structures.DocumentUri is
     (VSS.Strings.Conversions.To_Virtual_String (X) with null record);

   -------------
   -- Execute --
   -------------

   overriding procedure Execute
     (Self    : Command;
      Handler : not null access
        LSP.Server_Notification_Receivers.Server_Notification_Receiver'Class;
      Sender  : not null access LSP.Client_Message_Receivers.
        Client_Message_Receiver'Class;
      Id      : LSP.Structures.Integer_Or_Virtual_String;
      Error   : in out LSP.Errors.ResponseError_Optional)
   is
      use LAL_Refactor;

      function To_LSP_Diagnostic
        (Problem   : LAL_Refactor.Refactoring_Diagnostic'Class;
         Error_Msg : String)
         return LSP.Structures.Diagnostic;

      -----------------------
      -- To_LSP_Diagnostic --
      -----------------------

      function To_LSP_Diagnostic
        (Problem   : LAL_Refactor.Refactoring_Diagnostic'Class;
         Error_Msg : String)
         return LSP.Structures.Diagnostic
      is
         Diagnostic : LSP.Structures.Diagnostic;
      begin
         Diagnostic := LSP.Structures.Diagnostic'
           (a_range            => LSP.Utils.To_Range (Problem.Location),
            severity           => (True, LSP.Enumerations.Error),
            code               => <>,
            codeDescription    => <>,
            source             => VSS.Strings.Conversions.To_Virtual_String
              ("Ada"),
            message            => VSS.Strings.Conversions.To_Virtual_String
              (Error_Msg),
            tags               => <>,
            relatedInformation => <>,
            data               => <>);

         Diagnostic.relatedInformation.Append
              (LSP.Structures.DiagnosticRelatedInformation'(
               location => LSP.Structures.Location'
                 (uri     => To_DocumentUri (Problem.Filename),
                  a_range => LSP.Utils.To_Range (Problem.Location)),
               message  => VSS.Strings.Conversions.To_Virtual_String
                 (Problem.Info)));

         return Diagnostic;
      end To_LSP_Diagnostic;

      Name            : constant String :=
        LSP.Ada_Handlers.Refactor.Command'Class (Self).Name;
      Error_Msg       : constant String := "Failed to execute the "
        & Name
        & " refactoring.";
      Message_Handler : LSP.Ada_Handlers.Message_Handler renames
        LSP.Ada_Handlers.Message_Handler (Handler.all);
      Apply           : LSP.Structures.ApplyWorkspaceEditParams;
      Workspace_Edits : LSP.Structures.WorkspaceEdit renames Apply.edit;
      Label           : Virtual_String_Optional renames Apply.label;
      Edits           : LAL_Refactor.Refactoring_Edits;
   begin
      LSP.Ada_Handlers.Refactor.Command'Class (Self).Refactor
        (Handler => Handler,
         Sender  => Sender,
         Edits   => Edits);

      --  The refactoring failed to compute edits: send an error response
      --  and publish the diagnostics, if any
      if LAL_Refactor.Has_Failed (Edits) then
         Error :=
           (Is_Set => True,
            Value  =>
              (code    => LSP.Enumerations.UnknownErrorCode,
               message => VSS.Strings.Conversions.To_Virtual_String
                 (Error_Msg)));

         --  Publish the diagnostics when we have some
         if not Edits.Diagnostics.Is_Empty then
            declare
               Diagnostic  : LSP.Structures.Diagnostic;
               Diagnostics : LSP.Structures.Diagnostic_Vector;
               URI         : LSP.Structures.DocumentUri := To_DocumentUri ("");
               Document    : Document_Access;
               Idx         : Integer := 1;
            begin
               for Problem of Edits.Diagnostics loop
                  Document := Get_Open_Document
                    (Self  => Message_Handler,
                     URI   => To_DocumentUri (Problem.Filename),
                     Force => False);

                  --  Publish any processed diagnostic when switching to a
                  --  different file.
                  if not Diagnostics.Is_Empty
                    and then URI /= To_DocumentUri (Problem.Filename)
                  then
                     Publish_Diagnostics
                       (Self              => Message_Handler,
                        Document          => Document,
                        Other_Diagnostics => Diagnostics,
                        Force             => True);
                  end if;

                  URI := To_DocumentUri (Problem.Filename);
                  Diagnostic := To_LSP_Diagnostic (Problem, Error_Msg);
                  Diagnostics.Append (Diagnostic);

                  --  We have processed the last refactoring diagnostic:
                  --  publish all the LSP diagnostics we have.
                  if Idx = Integer (Edits.Diagnostics.Length) then
                     Publish_Diagnostics
                       (Self              => Message_Handler,
                        Document          => Document,
                        Other_Diagnostics => Diagnostics,
                        Force             => True);
                  end if;

                  Idx := Idx + 1;
               end loop;
            end;
         end if;
      else
         --  Apply the computed refactoring edits
         Workspace_Edits := To_Workspace_Edit
           (Self   => Message_Handler,
            Edits  => Edits,
            Rename => True);
         Label := VSS.Strings.Conversions.To_Virtual_String (Name);

         Sender.On_ApplyEdit_Request (Id, Apply);
      end if;

   exception
      when E : others =>
         Message_Handler.Tracer.Trace_Exception (E);
         Error :=
           (Is_Set => True,
            Value  =>
              (code    => LSP.Enumerations.UnknownErrorCode,
               message => VSS.Strings.Conversions.To_Virtual_String
                 (Error_Msg)));
   end Execute;

end LSP.Ada_Handlers.Refactor;
