{ *********************************************************** }
{ *                     TForge Library                      * }
{ *       Copyright (c) Sergey Kasandrov 1997, 2017         * }
{ *********************************************************** }

unit tfHashServ;

interface

{$I TFL.inc}

uses tfRecords, tfTypes, tfAlgServ, tfByteVectors,
     tfMD5, tfSHA1, tfSHA256, tfSHA512,
     tfCRC32, tfJenkinsOne,
     tfHMAC;

function GetHashServerInstance(var A: IHashServer): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF}

function GetHashInstance(AlgID: TF_AlgID; var Alg: IHash): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF}

implementation

(*
type
  PAlgItem = ^TAlgItem;
  TAlgItem = record
    Name: array[0..15] of Byte;
    Getter: Pointer;
  end;
*)

type
  PHashServer = ^THashServer;
  THashServer = record
  public const
    TABLE_SIZE = 64;
  public
                          // !! inherited from TAlgServer
    FVTable: PPointer;
    FCapacity: Integer;
    FCount: Integer;
    FAlgTable: array[0..TABLE_SIZE - 1] of TAlgItem;
(*
    FVTable: PPointer;
    FAlgTable: array[0..63] of TAlgItem;
    FCount: Integer;
    class function GetByAlgID(Inst: PHashServer; AlgID: Integer;
          var Alg: IHashAlgorithm): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
*)
    class function GetHMAC(Inst: PHashServer; var HMACAlg: IHMACAlgorithm;
//          Key: Pointer; KeySize: Cardinal;
          const HashAlg: IHash): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
    class function PBKDF1(Inst: PHashServer; HashAlg: IHash;
          Password: Pointer; PassLen: Cardinal; Salt: Pointer; SaltLen: Cardinal;
          Rounds, dkLen: Cardinal; var Key: PByteVector): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
(*
    class function GetByName(Inst: PHashServer; AName: Pointer; CharSize: Integer;
          var Alg: IHashAlgorithm): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
    class function GetByIndex(Inst: PHashServer; Index: Integer;
          var Alg: IHashAlgorithm): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
    class function GetName(Inst: PHashServer; Index: Integer;
          var Name: PByteVector): TF_RESULT;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
    class function GetCount(Inst: PHashServer): Integer;
          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;
*)
//    class function RegisterHash(Inst: PHashServer; Name: Pointer; CharSize: Integer;
//          Getter: THashGetter; var Index: Integer): TF_RESULT;
//          {$IFDEF TFL_STDCALL}stdcall;{$ENDIF} static;

  end;

const
  VTable: array[0..9] of Pointer = (
    @TForgeInstance.QueryIntf,
    @TForgeSingleton.Addref,
    @TForgeSingleton.Release,

    @TAlgServer.GetID,
    @TAlgServer.GetName,
    @TAlgServer.GetCount,
    @TAlgServer.GetIDByName,
    @TAlgServer.GetNameByID,

    @THashServer.GetHMAC,
    @THashServer.PBKDF1
//    @THashServer.RegisterHash,
  );

var
  Instance: THashServer;

const
  MD5_LITERAL: UTF8String = 'MD5';
  SHA1_LITERAL: UTF8String = 'SHA1';
  SHA256_LITERAL: UTF8String = 'SHA256';
  SHA512_LITERAL: UTF8String = 'SHA512';
  SHA224_LITERAL: UTF8String = 'SHA224';
  SHA384_LITERAL: UTF8String = 'SHA384';
  CRC32_LITERAL: UTF8String = 'CRC32';
  JENKINS1_LITERAL: UTF8String = 'JENKINS1';

(*
procedure AddTableItem(const AName: RawByteString; AGetter: Pointer);
var
  P: PAlgItem;
  L: Integer;

begin
  P:= @Instance.FAlgTable[Instance.FCount];
  FillChar(P^.Name, SizeOf(P^.Name), 0);
  L:= Length(AName);
  if L > SizeOf(P^.Name) then L:= SizeOf(P^.Name);
  Move(Pointer(AName)^, P^.Name, L);
  P^.Getter:= AGetter;
  Inc(Instance.FCount);
end;
*)

procedure InitInstance;
begin
  Instance.FVTable:= @VTable;
  Instance.FCapacity:= THashServer.TABLE_SIZE;
//  Instance.FCount:= 0;

  TAlgServer.AddTableItem(@Instance, Pointer(MD5_LITERAL), TF_ALG_MD5);
  TAlgServer.AddTableItem(@Instance, Pointer(SHA1_LITERAL), TF_ALG_SHA1);
  TAlgServer.AddTableItem(@Instance, Pointer(SHA256_LITERAL), TF_ALG_SHA256);
  TAlgServer.AddTableItem(@Instance, Pointer(SHA512_LITERAL), TF_ALG_SHA512);
  TAlgServer.AddTableItem(@Instance, Pointer(SHA224_LITERAL), TF_ALG_SHA224);
  TAlgServer.AddTableItem(@Instance, Pointer(SHA384_LITERAL), TF_ALG_SHA384);
  TAlgServer.AddTableItem(@Instance, Pointer(CRC32_LITERAL), TF_ALG_CRC32);
  TAlgServer.AddTableItem(@Instance, Pointer(JENKINS1_LITERAL), TF_ALG_JENKINS1);
end;

function GetHashServerInstance(var A: IHashServer): TF_RESULT;
begin
  if Instance.FVTable = nil then InitInstance;
// IHashServer is implemented by a singleton, no need for releasing old instance
  Pointer(A):= @Instance;
  Result:= TF_S_OK;
end;

{ THashServer }

class function THashServer.PBKDF1(Inst: PHashServer; HashAlg: IHash;
  Password: Pointer; PassLen: Cardinal; Salt: Pointer; SaltLen: Cardinal;
  Rounds, dkLen: Cardinal; var Key: PByteVector): TF_RESULT;

const
  MAX_DIGEST_SIZE = 128;   // = 1024 bits

var
  hLen: Cardinal;
  Digest: array[0 .. MAX_DIGEST_SIZE - 1] of Byte;

begin
  hLen:= HashAlg.GetDigestSize;
  if dkLen = 0 then dkLen:= hLen;
  if (hLen < dkLen) or (hLen > MAX_DIGEST_SIZE) then begin
    Result:= TF_E_INVALIDARG;
    Exit;
  end;
  HashAlg.Init;
  HashAlg.Update(Password, PassLen);
  HashAlg.Update(Salt, SaltLen);
  HashAlg.Done(@Digest);
  while Rounds > 1 do begin
    HashAlg.Init;
    HashAlg.Update(@Digest, hLen);
    HashAlg.Done(@Digest);
    Dec(Rounds);
  end;
  Result:= ByteVectorFromPByte(Key, @Digest, dkLen);
end;

function GetStdInstance(AlgID: TF_AlgID; var Alg: IHash): TF_RESULT;
begin
  case AlgID of
    TF_ALG_MD5: Result:= GetMD5Algorithm(PMD5Alg(Alg));
    TF_ALG_SHA1: Result:= GetSHA1Algorithm(PSHA1Alg(Alg));
    TF_ALG_SHA256: Result:= GetSHA256Algorithm(PSHA256Alg(Alg));
    TF_ALG_SHA512: Result:= GetSHA512Algorithm(PSHA512Alg(Alg));
    TF_ALG_SHA224: Result:= GetSHA224Algorithm(PSHA224Alg(Alg));
    TF_ALG_SHA384: Result:= GetSHA384Algorithm(PSHA384Alg(Alg));
  else
    case AlgID of
      TF_ALG_CRC32: Result:= GetCRC32Algorithm(PCRC32Alg(Alg));
      TF_ALG_JENKINS1: Result:= GetJenkinsOneAlgorithm(PJenkinsOneAlg(Alg));
    else
      Result:= TF_E_INVALIDARG;
    end;
  end;
end;

function GetOSSLInstance(AlgID: TF_AlgID; var Alg: IHash): TF_RESULT;
begin
      Result:= TF_E_INVALIDARG;
end;

function GetHashInstance(AlgID: TF_AlgID; var Alg: IHash): TF_RESULT;
begin
  case AlgID and TF_ENGINE_MASK of
    TF_ENGINE_STD:  Result:= GetStdInstance(AlgID and not TF_ENGINE_MASK, Alg);
    TF_ENGINE_OSSL: Result:= GetOSSLInstance(AlgID and not TF_ENGINE_MASK, Alg);
  else
    Result:= TF_E_INVALIDARG;
  end;
end;

class function THashServer.GetHMAC(Inst: PHashServer; var HMACAlg: IHMACAlgorithm;
                                   const HashAlg: IHash): TF_RESULT;
begin
  Result:= GetHMACAlgorithm(PHMACAlg(HMACAlg), HashAlg);
end;

(*
class function THashServer.GetByName(Inst: PHashServer; AName: Pointer;
        CharSize: Integer; var Alg: IHashAlgorithm): TF_RESULT;
const
  ANSI_a = Ord('a');

var
  I: Integer;
  PItem, Sentinel: PAlgItem;
  P1, P2: PByte;
  Found: Boolean;
  UP2: Byte;

begin
  PItem:= @Inst.FAlgTable;
  Sentinel:= PItem;
  Inc(Sentinel, Inst.FCount);
  while PItem <> Sentinel do begin
    P1:= @PItem.Name;
    P2:= AName;
    Found:= True;
    I:= SizeOf(PItem.Name);
    repeat
      UP2:= P2^;
      if UP2 >= ANSI_a then
        UP2:= UP2 and not $20;  { upcase }
      if P1^ <> UP2 then begin
        Found:= False;
        Break;
      end;
      if P1^ = 0 then Break;
      Inc(P1);
      Inc(P2, CharSize);
      Dec(I);
    until I = 0;
    if Found then begin
      Result:= THashGetter(PItem.Getter)(Alg);
//      Result:= TF_S_OK;
      Exit;
    end;
    Inc(PItem);
  end;
  Result:= TF_E_INVALIDARG;
end;

class function THashServer.GetByIndex(Inst: PHashServer; Index: Integer;
        var Alg: IHashAlgorithm): TF_RESULT;
begin
  if Cardinal(Index) >= Cardinal(Length(Inst.FAlgTable)) then
    Result:= TF_E_INVALIDARG
  else
    Result:= THashGetter(Inst.FAlgTable[Index].Getter)(Alg);
end;

class function THashServer.GetCount(Inst: PHashServer): Integer;
begin
  Result:= Inst.FCount;
end;

class function THashServer.GetName(Inst: PHashServer; Index: Integer;
        var Name: PByteVector): TF_RESULT;
var
  Tmp: PByteVector;
  P, P1: PByte;
  I: Integer;

begin
  if Cardinal(Index) >= Cardinal(Length(Instance.FAlgTable)) then
    Result:= TF_E_INVALIDARG
  else begin
    P:= @Inst.FAlgTable[Index].Name;
    P1:= P;
    I:= 0;
    repeat
      if P1^ = 0 then Break;
      Inc(P1);
      Inc(I);
    until I = 16;
    if I = 0 then
      Result:= TF_E_UNEXPECTED
    else begin
      Tmp:= nil;
      Result:= ByteVectorAlloc(Tmp, I);
      if Result = TF_S_OK then begin
        Move(P^, Tmp.FData, I);
        if Name <> nil then TtfRecord.Release(Name);
        Name:= Tmp;
      end;
    end;
  end;
end;
*)

{
class function THashServer.RegisterHash(Inst: PHashServer; Name: Pointer;
  CharSize: Integer; Getter: THashGetter; var Index: Integer): TF_RESULT;
begin
// todo:
end;
}
end.
