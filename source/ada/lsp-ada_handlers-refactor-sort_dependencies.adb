------------------------------------------------------------------------------
--                         Language Server Protocol                         --
--                                                                          --
--                        Copyright (C) 2023, AdaCore                       --
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

with Ada.Strings.UTF_Encoding;

with Langkit_Support.Slocs;

with Libadalang.Analysis;

with LAL_Refactor.Sort_Dependencies;

with LSP.Messages;

with VSS.Strings.Conversions;
with LSP.Commands;

package body LSP.Ada_Handlers.Refactor.Sort_Dependencies is

   ------------------------
   -- Append_Code_Action --
   ------------------------

   procedure Append_Code_Action
     (Self            : in out Command;
      Context         : Context_Access;
      Commands_Vector : in out LSP.Messages.CodeAction_Vector;
      Where           : LSP.Messages.Location)
   is
      Pointer     : LSP.Commands.Command_Pointer;
      Code_Action : LSP.Messages.CodeAction;

   begin
      Self.Initialize
        (Context           => Context.all,
         Where             => Where);

      Pointer.Set (Self);

      Code_Action :=
        (title       => "Sort Dependencies",
         kind        =>
           (Is_Set => True,
            Value  => LSP.Messages.Refactor),
         diagnostics => (Is_Set => False),
         edit        => (Is_Set => False),
         isPreferred => (Is_Set => False),
         disabled    => (Is_Set => False),
         command     =>
           (Is_Set => True,
            Value  =>
              (Is_Unknown => False,
               title      => <>,
               Custom     => Pointer)));

      Commands_Vector.Append (Code_Action);
   end Append_Code_Action;

   ------------
   -- Create --
   ------------

   overriding
   function Create
     (JS : not null access LSP.JSON_Streams.JSON_Stream'Class)
      return Command
   is
      use Ada.Strings.UTF_Encoding;
      use LSP.Messages;
      use LSP.Types;
      use VSS.Strings.Conversions;

   begin
      return C : Command do
         pragma Assert (JS.R.Is_Start_Object);

         JS.R.Read_Next;

         while not JS.R.Is_End_Object loop
            pragma Assert (JS.R.Is_Key_Name);

            declare
               Key : constant UTF_8_String := To_UTF_8_String (JS.R.Key_Name);

            begin
               JS.R.Read_Next;

               if Key = "context" then
                  Read_String (JS, C.Context);

               elsif Key = "where" then
                  Location'Read (JS, C.Where);

               else
                  JS.Skip_Value;
               end if;
            end;
         end loop;

         JS.R.Read_Next;
      end return;
   end Create;

   --------------
   -- Refactor --
   --------------

   overriding
   procedure Refactor
     (Self    : Command;
      Handler : not null access LSP.Server_Notification_Receivers.
        Server_Notification_Receiver'Class;
      Client  : not null access LSP.Client_Message_Receivers.
        Client_Message_Receiver'Class;
      Edits   : out LAL_Refactor.Refactoring_Edits)
   is
      use Langkit_Support.Slocs;
      use Libadalang.Analysis;
      use LAL_Refactor;
      use LAL_Refactor.Sort_Dependencies;
      use LSP.Types;

      Message_Handler : LSP.Ada_Handlers.Message_Handler renames
        LSP.Ada_Handlers.Message_Handler (Handler.all);
      Context         : LSP.Ada_Contexts.Context renames
        Message_Handler.Contexts.Get (Self.Context).all;

      Analysis_Unit    : constant Libadalang.Analysis.Analysis_Unit :=
        Context.LAL_Context.Get_From_File
          (Context.URI_To_File (Self.Where.uri));
      Sloc             : constant Source_Location :=
        (Langkit_Support.Slocs.Line_Number (Self.Where.span.first.line) + 1,
         Langkit_Support.Slocs.Column_Number (Self.Where.span.first.character)
         + 1);
      Compilation_Unit : constant Libadalang.Analysis.Compilation_Unit :=
        Analysis_Unit.Root.Lookup (Sloc).P_Enclosing_Compilation_Unit;

      Sorter : constant Dependencies_Sorter :=
        Create_Dependencies_Sorter (Compilation_Unit);

   begin
      Edits := Sorter.Refactor (null);
   end Refactor;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self    : in out Command'Class;
      Context : LSP.Ada_Contexts.Context;
      Where   : LSP.Messages.Location) is
   begin
      Self.Context := Context.Id;
      Self.Where   := Where;
   end Initialize;

   -------------------
   -- Write_Command --
   -------------------

   procedure Write_Command
     (S : access Ada.Streams.Root_Stream_Type'Class;
      C : Command)
   is
      use LSP.Messages;
      use LSP.Types;

      JS : LSP.JSON_Streams.JSON_Stream'Class renames
        LSP.JSON_Streams.JSON_Stream'Class (S.all);

   begin
      JS.Start_Object;
      JS.Key ("context");
      Write_String (S, C.Context);
      JS.Key ("where");
      Location'Write (S, C.Where);
      JS.End_Object;
   end Write_Command;

end LSP.Ada_Handlers.Refactor.Sort_Dependencies;