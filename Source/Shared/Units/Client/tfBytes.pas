{ *********************************************************** }
{ *                     TForge Library                      * }
{ *       Copyright (c) Sergey Kasandrov 1997, 2014         * }
{ *********************************************************** }

unit tfBytes;

{$I TFL.inc}

interface

uses SysUtils, tfTypes, tfConsts, tfExceptions,
    {$IFDEF TFL_DLL} tfImport {$ELSE} tfByteVectors {$ENDIF};

type
  ByteArray = record
  private
    FBytes: IBytes;
    function GetByte(Index: Integer): Byte;
    procedure SetByte(Index: Integer; const Value: Byte);
  public
    function IsAssigned: Boolean;
    procedure Free;

    function GetEnumerator: IBytesEnumerator;
    function GetHashCode: Integer;
    property HashCode: Integer read GetHashCode;

    function GetLen: Integer;
    procedure SetLen(Value: Integer);
    function GetRawData: PByte;

    property Len: Integer read GetLen write SetLen;
    property RawData: PByte read GetRawData;

    class function Allocate(ASize: Cardinal): ByteArray; static;
    class function ReAllocate(ASize: Cardinal): ByteArray; static;
    class function FromText(const S: string): ByteArray; static;
    class function FromAnsi(const S: RawByteString): ByteArray; static;
    class function ParseHex(const S: string): ByteArray; static;
    class function TryParseHex(const S: string; var R: ByteArray): Boolean; static;
    class function ParseBitString(const S: string; ABitLen: Integer): ByteArray; static;

    function ToText: string;
    function ToString: string;
    function ToHex: string;

    class function Copy(const A: ByteArray): ByteArray; overload; static;
    class function Copy(const A: ByteArray; I: Cardinal): ByteArray; overload; static;
    class function Copy(const A: ByteArray; I, L: Cardinal): ByteArray; overload; static;

    class function Insert(const A: ByteArray; I: Cardinal; B: Byte): ByteArray; overload; static;
    class function Insert(const A: ByteArray; I: Cardinal; B: ByteArray): ByteArray; overload; static;
    class function Insert(const A: ByteArray; I: Cardinal; B: TBytes): ByteArray; overload; static;

    class function Remove(const A: ByteArray; I: Cardinal): ByteArray; overload; static;
    class function Remove(const A: ByteArray; I, L: Cardinal): ByteArray; overload; static;

    class function AddBytes(const A, B: ByteArray): ByteArray; static;
    class function SubBytes(const A, B: ByteArray): ByteArray; static;
    class function AndBytes(const A, B: ByteArray): ByteArray; static;
    class function OrBytes(const A, B: ByteArray): ByteArray; static;
    class function XorBytes(const A, B: ByteArray): ByteArray; static;

    class operator Explicit(const Value: ByteArray): Pointer;
    class operator Explicit(const Value: Byte): ByteArray;
    class operator Implicit(const Value: ByteArray): TBytes;
    class operator Implicit(const Value: TBytes): ByteArray;

    class operator Equal(const A, B: ByteArray): Boolean;
    class operator Equal(const A: ByteArray; const B: TBytes): Boolean;
    class operator Equal(const A: TBytes; const B: ByteArray): Boolean;
    class operator Equal(const A: ByteArray; const B: Byte): Boolean;
    class operator Equal(const A: Byte; const B: ByteArray): Boolean;

    class operator NotEqual(const A, B: ByteArray): Boolean; inline;
    class operator NotEqual(const A: ByteArray; const B: TBytes): Boolean; inline;
    class operator NotEqual(const A: TBytes; const B: ByteArray): Boolean; inline;
    class operator NotEqual(const A: ByteArray; const B: Byte): Boolean; inline;
    class operator NotEqual(const A: Byte; const B: ByteArray): Boolean; inline;

    class operator Add(const A, B: ByteArray): ByteArray;
    class operator Add(const A: ByteArray; const B: TBytes): ByteArray;
    class operator Add(const A: ByteArray; const B: Byte): ByteArray;
    class operator Add(const A: TBytes; const B: ByteArray): ByteArray;
    class operator Add(const A: Byte; const B: ByteArray): ByteArray;

    class operator BitwiseAnd(const A, B: ByteArray): ByteArray;
    class operator BitwiseOr(const A, B: ByteArray): ByteArray;
    class operator BitwiseXor(const A, B: ByteArray): ByteArray;

    property Bytes[Index: Integer]: Byte read GetByte write SetByte; default;
  end;

type
  EByteArrayError = class(EForgeError);

implementation

procedure ByteArrayError(ACode: TF_RESULT; const Msg: string = '');
begin
  raise EByteArrayError.Create(ACode, Msg);
end;

procedure HResCheck(Value: TF_RESULT); inline;
begin
  if Value <> TF_S_OK then
    ByteArrayError(Value);
end;

{ ByteArray }

function ByteArray.GetByte(Index: Integer): Byte;
begin
  if Cardinal(Index) < Cardinal(FBytes.GetLen) then
    Result:= FBytes.GetRawData[Index]
  else
    raise EArgumentOutOfRangeException.CreateResFmt(@SIndexOutOfRange, [Index]);
end;

procedure ByteArray.SetByte(Index: Integer; const Value: Byte);
begin
  if Cardinal(Index) < Cardinal(FBytes.GetLen) then
    FBytes.GetRawData[Index]:= Value
  else
    raise EArgumentOutOfRangeException.CreateResFmt(@SIndexOutOfRange, [Index]);
end;

function ByteArray.GetEnumerator: IBytesEnumerator;
begin
{$IFDEF TFL_DLL}
  HResCheck(FBytes.GetEnumerator(Result));
{$ELSE}
  HResCheck(TByteVector.GetEnum(PByteVector(FBytes), PByteVectorEnum(Result)));
{$ENDIF}
end;

function ByteArray.GetHashCode: Integer;
begin
{$IFDEF TFL_DLL}
  Result:= FBytes.GetHashCode;
{$ELSE}
  Result:= TByteVector.GetHashCode(PByteVector(FBytes));
{$ENDIF}
end;

function ByteArray.GetLen: Integer;
begin
{$IFDEF TFL_DLL}
  Result:= FBytes.GetLen;
{$ELSE}
  Result:= TByteVector.GetLen(PByteVector(FBytes));
{$ENDIF}
end;

procedure ByteArray.SetLen(Value: Integer);
begin
{$IFDEF TFL_DLL}
  HResCheck(FBytes.SetLen(Value));
{$ELSE}
  HResCheck(TByteVector.SetLen(PByteVector(FBytes), Value));
{$ENDIF}
end;

function ByteArray.GetRawData: PByte;
begin
{$IFDEF TFL_DLL}
  Result:= FBytes.GetRawData;
{$ELSE}
  Result:= TByteVector.GetRawData(PByteVector(FBytes));
{$ENDIF}
end;

class operator ByteArray.Implicit(const Value: ByteArray): TBytes;
var
  L: Integer;

begin
  Result:= nil;

{$IFDEF TFL_DLL}
  L:= Value.FBytes.GetLen;
  if L > 0 then begin
    SetLength(Result, L);
    Move(Value.FBytes.GetRawData^, Pointer(Result)^, L);
  end;
{$ELSE}
  L:= TByteVector.GetLen(PByteVector(Value.FBytes));
  if L > 0 then begin
    SetLength(Result, L);
    Move(TByteVector.GetRawData(PByteVector(Value.FBytes))^, Pointer(Result)^, L);
  end;
{$ENDIF}
end;

class operator ByteArray.Implicit(const Value: TBytes): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorFromPByte(Result.FBytes, Pointer(Value), Length(Value)));
{$ELSE}
  HResCheck(ByteVectorFromPByte(PByteVector(Result.FBytes), Pointer(Value), Length(Value)));
{$ENDIF}
end;

class function ByteArray.Insert(const A: ByteArray; I: Cardinal; B: Byte): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.InsertByte(I, B, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.InsertByte(PByteVector(A.FBytes), I, B, PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.Insert(const A: ByteArray; I: Cardinal; B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.InsertBytes(I, B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.InsertBytes(PByteVector(A.FBytes), I, PByteVector(B.FBytes),
                                    PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.Insert(const A: ByteArray; I: Cardinal; B: TBytes): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.InsertPByte(I, Pointer(B), Length(B), Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.InsertPByte(PByteVector(A.FBytes), I, Pointer(B), Length(B),
                        PByteVector(Result.FBytes)));
{$ENDIF}
end;

function ByteArray.IsAssigned: Boolean;
begin
  Result:= FBytes <> nil;
end;

class function ByteArray.Remove(const A: ByteArray; I: Cardinal): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.RemoveBytes1(Result.FBytes), I);
{$ELSE}
  HResCheck(TByteVector.RemoveBytes1(PByteVector(A.FBytes),
                                     PByteVector(Result.FBytes), I));
{$ENDIF}
end;

class function ByteArray.Remove(const A: ByteArray; I, L: Cardinal): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.RemoveBytes2(Result.FBytes, I, L));
{$ELSE}
  HResCheck(TByteVector.RemoveBytes2(PByteVector(A.FBytes),
                        PByteVector(Result.FBytes), I, L));
{$ENDIF}
end;

class operator ByteArray.Explicit(const Value: Byte): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorFromByte(Result.FBytes, Value));
{$ELSE}
  HResCheck(ByteVectorFromByte(PByteVector(Result.FBytes), Value));
{$ENDIF}
end;

class operator ByteArray.Explicit(const Value: ByteArray): Pointer;
begin
{$IFDEF TFL_DLL}
  Result:= Value.FBytes.GetRawData;
{$ELSE}
  Result:= TByteVector.GetRawData(PByteVector(Value.FBytes));
{$ENDIF}
end;

class function ByteArray.Allocate(ASize: Cardinal): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorAlloc(Result.FBytes, ASize));
{$ELSE}
  HResCheck(ByteVectorAlloc(PByteVector(Result.FBytes), ASize));
{$ENDIF}
end;

class function ByteArray.ReAllocate(ASize: Cardinal): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorReAlloc(Result.FBytes, ASize));
{$ELSE}
  HResCheck(ByteVectorReAlloc(PByteVector(Result.FBytes), ASize));
{$ENDIF}
end;

class function ByteArray.ParseBitString(const S: string; ABitLen: Integer): ByteArray;
var
  Ch: Char;
  I: Integer;
  Tmp: Cardinal;
  P: PByte;

begin
  if (ABitLen <= 0) or (ABitLen > 8) or (Length(S) mod ABitLen <> 0) then
    raise Exception.Create('Wrong string length');

{$IFDEF TFL_DLL}
  HResCheck(ByteVectorAlloc(Result.FBytes, Length(S) div ABitLen));
{$ELSE}
  HResCheck(ByteVectorAlloc(PByteVector(Result.FBytes), Length(S) div ABitLen));
{$ENDIF}

//  SetLength(Result.FBytes, Length(S) div 7);
  P:= Result.FBytes.GetRawData;
  I:= 0;
  Tmp:= 0;
  for Ch in S do begin
    Tmp:= Tmp shl 1;
    if Ch = '1' then Tmp:= Tmp or 1
    else if Ch <> '0' then
      raise Exception.Create('Wrong string char');
    Inc(I);
    if I mod 7 = 0 then begin
//      Result.FBytes[I div 7 - 1]:= Tmp;
      P^:= Tmp;
      Inc(P);
      Tmp:= 0;
    end;
  end;
end;

class function ByteArray.ParseHex(const S: string): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorFromPCharHex(Result.FBytes, Pointer(S), Length(S), SizeOf(Char)));
{$ELSE}
  HResCheck(ByteVectorFromPCharHex(PByteVector(Result.FBytes),
                                   Pointer(S), Length(S), SizeOf(Char)));
{$ENDIF}
end;

procedure ByteArray.Free;
begin
  FBytes:= nil;
end;

class function ByteArray.FromAnsi(const S: RawByteString): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorFromPByte(Result.FBytes, Pointer(S), Length(S)));
{$ELSE}
  HResCheck(ByteVectorFromPByte(PByteVector(Result.FBytes), Pointer(S), Length(S)));
{$ENDIF}
end;

class function ByteArray.FromText(const S: string): ByteArray;
var
  S8: UTF8String;

begin
  S8:= UTF8String(S);
{$IFDEF TFL_DLL}
  HResCheck(ByteVectorFromPByte(Result.FBytes, Pointer(S8), Length(S8)));
{$ELSE}
  HResCheck(ByteVectorFromPByte(PByteVector(Result.FBytes), Pointer(S8), Length(S8)));
{$ENDIF}
end;

function ByteArray.ToHex: string;
const
  ASCII_0 = Ord('0');
  ASCII_A = Ord('A');

var
  L: Integer;
  P: PByte;
  B: Byte;
  PS: PChar;

begin
  L:= GetLen;
  SetLength(Result, 2 * L);
  P:= GetRawData;
  PS:= PChar(Result);
  while L > 0 do begin
    B:= P^ shr 4;
    if B < 10 then
      PS^:= Char(B + ASCII_0)
    else
      PS^:= Char(B - 10 + ASCII_A);
    Inc(PS);
    B:= P^ and $0F;
    if B < 10 then
      PS^:= Char(B + ASCII_0)
    else
      PS^:= Char(B - 10 + ASCII_A);
    Inc(PS);
    Inc(P);
    Dec(L);
  end;
end;

function ByteArray.ToString: string;
var
  Tmp: IBytes;
  L, N: Integer;
  P: PByte;
  P1: PChar;

begin
  Result:= '';
  L:= GetLen;
  if L = 0 then Exit;
{$IFDEF TFL_DLL}
  HResCheck(FBytes.ToDec(Tmp));
{$ELSE}
  HResCheck(TByteVector.ToDec(PByteVector(FBytes), PByteVector(Tmp)));
{$ENDIF}
  P:= Tmp.GetRawData;
  N:= Tmp.GetLen;
  SetLength(Result, N);
  P1:= PChar(Result);
  repeat
    if P^ <> 0 then begin
      P1^:= Char(P^);
    end
    else begin
      P1^:= Char($20); // space
    end;
    Inc(P);
    Inc(P1);
    Dec(N);
  until N = 0;
end;

function ByteArray.ToText: string;
var
  S8: UTF8String;
  L: Integer;

begin
  if FBytes = nil then Result:= ''
  else begin
    L:= FBytes.GetLen;
    SetLength(S8, L);
    Move(FBytes.GetRawData^, Pointer(S8)^, L);
    Result:= string(S8);
  end;
end;

class function ByteArray.TryParseHex(const S: string; var R: ByteArray): Boolean;
begin
  Result:= (
{$IFDEF TFL_DLL}
    ByteVectorFromPCharHex(R.FBytes, Pointer(S), Length(S), SizeOf(Char))
{$ELSE}
    ByteVectorFromPCharHex(PByteVector(R.FBytes),
                                   Pointer(S), Length(S), SizeOf(Char))
{$ENDIF}
      = TF_S_OK);
end;

class operator ByteArray.Add(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.ConcatBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.ConcatBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.Add(const A: ByteArray; const B: TBytes): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.AppendPByte(Pointer(B), Length(B), Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.AppendPByte(PByteVector(A.FBytes),
            Pointer(B), Length(B), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.Add(const A: TBytes; const B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(B.FBytes.InsertPByte(0, Pointer(A), Length(A), Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.InsertPByte(PByteVector(B.FBytes), 0,
            Pointer(A), Length(A), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.Add(const A: ByteArray; const B: Byte): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.AppendByte(B, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.AppendByte(PByteVector(A.FBytes),
            B, PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.Add(const A: Byte; const B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(B.FBytes.InsertByte(0, A, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.InsertByte(PByteVector(B.FBytes), 0,
            A, PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.AddBytes(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.AddBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.AddBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.SubBytes(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.SubBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.SubBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.AndBytes(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.AndBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.AndBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.OrBytes(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.OrBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.OrBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.XorBytes(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.XorBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.XorBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.BitwiseAnd(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.AndBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.AndBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.BitwiseOr(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.OrBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.OrBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.BitwiseXor(const A, B: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.XorBytes(B.FBytes, Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.XorBytes(PByteVector(A.FBytes),
            PByteVector(B.FBytes), PByteVector(Result.FBytes)));
{$ENDIF}
end;

class operator ByteArray.Equal(const A, B: ByteArray): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= A.FBytes.EqualBytes(B.FBytes);
{$ELSE}
  Result:= TByteVector.EqualBytes(PByteVector(A.FBytes), PByteVector(B.FBytes));
{$ENDIF}
end;

class operator ByteArray.Equal(const A: ByteArray; const B: TBytes): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= A.FBytes.EqualToPByte(Pointer(B), Length(B));
{$ELSE}
  Result:= TByteVector.EqualToPByte(PByteVector(A.FBytes), Pointer(B), Length(B));
{$ENDIF}
end;

class operator ByteArray.Equal(const A: TBytes; const B: ByteArray): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= B.FBytes.EqualToPByte(Pointer(A), Length(A));
{$ELSE}
  Result:= TByteVector.EqualToPByte(PByteVector(B.FBytes), Pointer(A), Length(A));
{$ENDIF}
end;

class operator ByteArray.Equal(const A: ByteArray; const B: Byte): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= A.FBytes.EqualToByte(B);
{$ELSE}
  Result:= TByteVector.EqualToByte(PByteVector(A.FBytes), B);
{$ENDIF}
end;

class operator ByteArray.Equal(const A: Byte; const B: ByteArray): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= B.FBytes.EqualToByte(A);
{$ELSE}
  Result:= TByteVector.EqualToByte(PByteVector(B.FBytes), A);
{$ENDIF}
end;

class operator ByteArray.NotEqual(const A, B: ByteArray): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= not A.FBytes.EqualBytes(B.FBytes);
{$ELSE}
  Result:= not TByteVector.EqualBytes(PByteVector(A.FBytes), PByteVector(B.FBytes));
{$ENDIF}
end;

class operator ByteArray.NotEqual(const A: ByteArray; const B: TBytes): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= not A.FBytes.EqualToPByte(Pointer(B), Length(B));
{$ELSE}
  Result:= not TByteVector.EqualToPByte(PByteVector(A.FBytes), Pointer(B), Length(B));
{$ENDIF}
end;

class operator ByteArray.NotEqual(const A: TBytes; const B: ByteArray): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= not B.FBytes.EqualToPByte(Pointer(A), Length(A));
{$ELSE}
  Result:= not TByteVector.EqualToPByte(PByteVector(B.FBytes), Pointer(A), Length(A));
{$ENDIF}
end;

class operator ByteArray.NotEqual(const A: ByteArray; const B: Byte): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= not A.FBytes.EqualToByte(B);
{$ELSE}
  Result:= not TByteVector.EqualToByte(PByteVector(A.FBytes), B);
{$ENDIF}
end;

class operator ByteArray.NotEqual(const A: Byte; const B: ByteArray): Boolean;
begin
{$IFDEF TFL_DLL}
  Result:= not B.FBytes.EqualToByte(A);
{$ELSE}
  Result:= not TByteVector.EqualToByte(PByteVector(B.FBytes), A);
{$ENDIF}
end;

class function ByteArray.Copy(const A: ByteArray): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.CopyBytes(Result.FBytes));
{$ELSE}
  HResCheck(TByteVector.CopyBytes(PByteVector(A.FBytes),
                                  PByteVector(Result.FBytes)));
{$ENDIF}
end;

class function ByteArray.Copy(const A: ByteArray; I: Cardinal): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.CopyBytes1(Result.FBytes), I);
{$ELSE}
  HResCheck(TByteVector.CopyBytes1(PByteVector(A.FBytes),
                                   PByteVector(Result.FBytes), I));
{$ENDIF}
end;

class function ByteArray.Copy(const A: ByteArray; I, L: Cardinal): ByteArray;
begin
{$IFDEF TFL_DLL}
  HResCheck(A.FBytes.CopyBytes2(Result.FBytes, I, L));
{$ELSE}
  HResCheck(TByteVector.CopyBytes2(PByteVector(A.FBytes),
                                   PByteVector(Result.FBytes), I, L));
{$ENDIF}
end;

end.
