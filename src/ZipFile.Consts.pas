{ ZipFile.Consts.pas

  Public string resources of the ZIP module (split from ZipFile.pas per
  v4.1 Wave 3a refactor). Backward compat via re-export aliases in
  ZipFile.pas — `uses ZipFile` consumers continue to see the same
  resourcestring identifiers.
}
unit ZipFile.Consts;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

resourcestring
  rsFilenameSDoesNotExistInS = 'Filename %s does not exist in %s';
  rsZipFileSDoesNotExist = 'ZipFile %s does not exist';

implementation

end.
