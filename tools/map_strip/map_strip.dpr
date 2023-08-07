// An unused range was found in the map file
// between arrays UNIT_HEALTH and MAP.
// This tool stores only the data needed in the game.
//
// PETROBOTS.ASM:
//
//   ;***MAP FILES CONSIST OF EVERYTHING FROM THIS POINT ON***
//   UNIT_TYPE	=$5D00	;Unit type 0=none (64 bytes)
//   UNIT_LOC_X	=$5D40	;Unit X location (64 bytes)
//   UNIT_LOC_Y	=$5D80	;Unit X location (64 bytes)
//   UNIT_A		=$5DC0
//   UNIT_B		=$5E00
//   UNIT_C		=$5E40
//   UNIT_D		=$5E80
//   UNIT_HEALTH	=$5EC0	;Unit health (0 to 11) (64 bytes)
// ->   $6000-$5EC0+$40 = 256 bytes
//   MAP		=$6000	;Location of MAP (8K)
//   ;***END OF MAP FILE***


program map_strip;

{$APPTYPE CONSOLE}

uses
  SysUtils;

var
    levelprefix: char;
    levelname: string;
    i: Integer;

procedure fixlevel(fname: string);
var
  fin, fout: file of Byte;
  fpath: string;
  by: Byte;
  i: Integer;
begin
  fpath := 'd:\Z80\Projects\PetRobots\res\';
  AssignFile(fin, fpath+fname);
  Reset(fin);
  AssignFile(fout, fpath+fname+'.bin');
  Rewrite(fout);
  Writeln(' ok.');
  read(fin, by);
  read(fin, by);
  for i:=0 to 8*64-1 do begin
    read(fin, by);
    write(fout,by);
  end;
  for i:=0 to 255 do begin
    read(fin, by);
  end;
  for i:=0 to 8*1024-1 do begin
    read(fin, by);
    write(fout,by);
  end;
  CloseFile(fin);
  CloseFile(fout);
end;

begin
    levelprefix := 'a';
    for i:=0 to 9 do begin
      levelname := 'level-'+levelprefix;
      inc(levelprefix);
      Write(levelname);
      fixlevel(levelname);
    end;
    Readln;
end.
