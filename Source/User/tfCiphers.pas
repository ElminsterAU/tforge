{ *********************************************************** }
{ *                     TForge Library                      * }
{ *       Copyright (c) Sergey Kasandrov 1997, 2015         * }
{ *********************************************************** }

unit tfCiphers;

interface

{$I TFL.inc}

uses
  SysUtils, Classes, tfTypes, tfBytes, tfConsts, tfExceptions,
  {$IFDEF TFL_DLL} tfImport {$ELSE} tfCipherServ, tfKeyStreams {$ENDIF};

type
  TCipher = record
  private
    FAlgorithm: ICipherAlgorithm;
    procedure SetFlagsProc(const Value: LongWord);
    procedure SetIVProc(const Value: ByteArray);
    procedure SetNonceProc(const Value: ByteArray);
    function GetBlockSize: Cardinal;
  public
    class function Create(const Alg: ICipherAlgorithm): TCipher; static;
    procedure Free;
    function IsAssigned: Boolean;

    function SetFlags(AFlags: LongWord): TCipher; overload;

    function SetIV(AIV: Pointer; AIVLen: LongWord): TCipher; overload;
    function SetIV(const AIV: ByteArray): TCipher; overload;

    function SetNonce(const Value: ByteArray): TCipher; overload;
    function SetNonce(const Value: UInt64): TCipher; overload;
    function GetNonce: UInt64;
//    function SetBlockNo(const Value: ByteArray): TCipher; overload;
//    function SetBlockNo(const Value: UInt64): TCipher; overload;

    function ExpandKey(AKey: PByte; AKeyLen: LongWord): TCipher; overload;
    function ExpandKey(AKey: PByte; AKeyLen: LongWord; AFlags: LongWord): TCipher; overload;
    function ExpandKey(AKey: PByte; AKeyLen: LongWord; AFlags: LongWord;
                       AIV: Pointer; AIVLen: LongWord): TCipher; overload;

    function ExpandKey(const AKey: ByteArray): TCipher; overload;
    function ExpandKey(const AKey: ByteArray; AFlags: LongWord): TCipher; overload;
    function ExpandKey(const AKey: ByteArray; AFlags: LongWord;
                       const AIV: ByteArray): TCipher; overload;

    procedure Burn;

    procedure Encrypt(var Data; var DataSize: LongWord;
                      BufSize: LongWord; Last: Boolean); // overload;
    procedure Decrypt(var Data; var DataSize: LongWord;
                      Last: Boolean); // overload;
    procedure KeyCrypt(var Data; DataSize: LongWord;
                        Last: Boolean);

    procedure GetKeyStream(var Data; DataSize: LongWord);
    function KeyStream(DataSize: LongWord): ByteArray;

    function EncryptBlock(const Data, Key: ByteArray): ByteArray;
    function DecryptBlock(const Data, Key: ByteArray): ByteArray;

    function EncryptData(const Data: ByteArray): ByteArray;
    function DecryptData(const Data: ByteArray): ByteArray;

    procedure EncryptStream(InStream, OutStream: TStream; BufSize: LongWord = 0);
    procedure DecryptStream(InStream, OutStream: TStream; BufSize: LongWord = 0);

    procedure EncryptFile(const InName, OutName: string; BufSize: LongWord = 0);
    procedure DecryptFile(const InName, OutName: string; BufSize: LongWord = 0);

    function Skip(Value: LongWord): TCipher; overload;
    function Skip(Value: UInt64): TCipher; overload;
//    function Skip(Value: ByteArray): TCipher; overload;

    class function AES: TCipher; static;
    class function DES: TCipher; static;
    class function TripleDES: TCipher; static;
    class function RC5: TCipher; overload; static;
    class function RC5(BlockSize, Rounds: LongWord): TCipher; overload; static;
    class function RC4: TCipher; static;
    class function Salsa20: TCipher; overload; static;
    class function Salsa20(Rounds: LongWord): TCipher; overload; static;
    class function ChaCha20: TCipher; overload; static;
    class function ChaCha20(Rounds: LongWord): TCipher; overload; static;

    function Copy: TCipher;

    class operator Explicit(const Name: string): TCipher;
    class operator Explicit(AlgID: Integer): TCipher;

    class function AlgName(Index: Cardinal): string; static;
    class function AlgCount: Integer; static;

    property Algorithm: ICipherAlgorithm read FAlgorithm;

    property Flags: LongWord write SetFlagsProc;
    property IV: ByteArray write SetIVProc;
    property Nonce: ByteArray write SetNonceProc;
    property BlockSize: Cardinal read GetBlockSize;
  end;

  TKeyStream = record
  private
    FKeyStream: IKeyStream;
  public
    procedure Free;
    function IsAssigned: Boolean;
    procedure Burn;

    function ExpandKey(const AKey: ByteArray; ANonce: UInt64): TKeyStream; overload;
    function ExpandKey(AKey: PByte; AKeyLen: LongWord; ANonce: UInt64): TKeyStream; overload;
    function Skip(AValue: Int64): TKeyStream; // overload;

    procedure Read(var Data; DataLen: LongWord);
    procedure Crypt(var Data; DataLen: LongWord);
    function KeyStream(ASize: Cardinal): ByteArray;

    class function AES: TKeyStream; static;
    class function DES: TKeyStream; static;
    class function TripleDES: TKeyStream; static;
    class function RC5: TKeyStream; overload; static;
    class function RC5(BlockSize, Rounds: LongWord): TKeyStream; overload; static;
    class function RC4: TKeyStream; static;
    class function Salsa20: TKeyStream; overload; static;
    class function Salsa20(Rounds: LongWord): TKeyStream; overload; static;
    class function ChaCha20: TKeyStream; overload; static;
    class function ChaCha20(Rounds: LongWord): TKeyStream; overload; static;

    class operator Explicit(const Name: string): TKeyStream;
    class operator Explicit(AlgID: Integer): TKeyStream;
  end;

type
  ECipherError = class(EForgeError);

implementation

var
  FServer: ICipherServer;

procedure CipherError(ACode: TF_RESULT; const Msg: string = '');
begin
  raise ECipherError.Create(ACode, Msg);
end;

procedure HResCheck(Value: TF_RESULT); inline;
begin
  if Value <> TF_S_OK then
    CipherError(Value);
end;

{ TCipher }

class function TCipher.Create(const Alg: ICipherAlgorithm): TCipher;
begin
  Result.FAlgorithm:= Alg;
end;

procedure TCipher.Free;
begin
  FAlgorithm:= nil;
end;

function TCipher.GetBlockSize: Cardinal;
begin
  Result:= FAlgorithm.GetBlockSize;
end;

procedure TCipher.GetKeyStream(var Data; DataSize: LongWord);
begin
  HResCheck(FAlgorithm.GetKeyStream(@Data, DataSize));
end;

function TCipher.GetNonce: UInt64;
var
  DataLen: Cardinal;

begin
  DataLen:= SizeOf(UInt64);
  HResCheck(FAlgorithm.GetKeyParam(TF_KP_NONCE, @Result, DataLen));
end;

function TCipher.KeyStream(DataSize: LongWord): ByteArray;
begin
  Result:= ByteArray.Allocate(DataSize);
  GetKeyStream(Result.RawData^, DataSize);
end;

function TCipher.IsAssigned: Boolean;
begin
  Result:= FAlgorithm <> nil;
end;

class function TCipher.AES: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_AES, Result.FAlgorithm));
end;

class function TCipher.DES: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_DES, Result.FAlgorithm));
end;

class function TCipher.TripleDES: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_3DES, Result.FAlgorithm));
end;

class function TCipher.RC4: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_RC4, Result.FAlgorithm));
end;

class function TCipher.RC5: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_RC5, Result.FAlgorithm));
end;

class function TCipher.RC5(BlockSize, Rounds: LongWord): TCipher;
begin
  HResCheck(FServer.GetRC5(BlockSize, Rounds, Result.FAlgorithm));
end;

function TCipher.ExpandKey(AKey: PByte; AKeyLen, AFlags: LongWord;
                           AIV: Pointer; AIVLen: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @AFlags, SizeOf(AFlags)));
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_IV, AIV, AIVLen));
  HResCheck(FAlgorithm.ExpandKey(AKey, AKeyLen));
  Result:= Self;
end;

function TCipher.ExpandKey(const AKey: ByteArray; AFlags: LongWord;
                           const AIV: ByteArray): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @AFlags, SizeOf(AFlags)));
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_IV, AIV.RawData, AIV.Len));
  HResCheck(FAlgorithm.ExpandKey(AKey.RawData, AKey.Len));
  Result:= Self;
end;

function TCipher.ExpandKey(AKey: PByte; AKeyLen: LongWord; AFlags: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @AFlags, SizeOf(AFlags)));
{
//  if AKeyMode <> 0 then
    HResCheck(FAlgorithm.SetKeyParam(TF_KP_MODE, @AKeyMode, SizeOf(AKeyMode)));
//  if APadding <> 0 then
    HResCheck(FAlgorithm.SetKeyParam(TF_KP_PADDING, @APadding, SizeOf(APadding)));
}
  HResCheck(FAlgorithm.ExpandKey(AKey, AKeyLen));
  Result:= Self;
end;

function TCipher.ExpandKey(const AKey: ByteArray; AFlags: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @AFlags, SizeOf(AFlags)));
  HResCheck(FAlgorithm.ExpandKey(AKey.RawData, AKey.Len));
  Result:= Self;
end;

procedure TCipher.Burn;
begin
  FAlgorithm.BurnKey;
end;

procedure TCipher.Encrypt(var Data; var DataSize: LongWord;
  BufSize: LongWord; Last: Boolean);
begin
  HResCheck(FAlgorithm.Encrypt(@Data, DataSize, BufSize, Last));
end;

procedure TCipher.Decrypt(var Data; var DataSize: LongWord; Last: Boolean);
begin
  HResCheck(FAlgorithm.Decrypt(@Data, DataSize, Last));
end;

procedure TCipher.KeyCrypt(var Data; DataSize: LongWord; Last: Boolean);
begin
  HResCheck(FAlgorithm.KeyCrypt(@Data, DataSize, Last));
end;

function TCipher.EncryptBlock(const Data, Key: ByteArray): ByteArray;
var
  Flags: LongWord;
  BlockSize: Integer;

begin
  BlockSize:= FAlgorithm.GetBlockSize;
  if (BlockSize = 0) or (BlockSize <> Data.GetLen) then
    CipherError(TF_E_UNEXPECTED);

  Flags:= ECB_ENCRYPT;
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @Flags, SizeOf(Flags)));
  HResCheck(FAlgorithm.ExpandKey(Key.RawData, Key.Len));

  Result:= Data.Copy();
  FAlgorithm.EncryptBlock(Result.RawData);
end;

function TCipher.DecryptBlock(const Data, Key: ByteArray): ByteArray;
var
  Flags: LongWord;
  BlockSize: Integer;

begin
  BlockSize:= FAlgorithm.GetBlockSize;
  if (BlockSize = 0) or (BlockSize <> Data.GetLen) then
    CipherError(TF_E_UNEXPECTED);

  Flags:= ECB_DECRYPT;
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @Flags, SizeOf(Flags)));
  HResCheck(FAlgorithm.ExpandKey(Key.RawData, Key.Len));

  Result:= Data.Copy;
  FAlgorithm.DecryptBlock(Result.RawData);
end;

function TCipher.EncryptData(const Data: ByteArray): ByteArray;
var
  L0, L1: LongWord;

begin
  L0:= Data.GetLen;
  L1:= L0;
  if (FAlgorithm.Encrypt(nil, L1, 0, True) <> TF_E_INVALIDARG) or (L1 <= 0)
    then CipherError(TF_E_UNEXPECTED);

  Result:= Data;
  Result.ReAllocate(L1);
  HResCheck(FAlgorithm.Encrypt(Result.RawData, L0, L1, True));
end;

procedure TCipher.EncryptFile(const InName, OutName: string; BufSize: LongWord);
var
  InStream, OutStream: TStream;

begin
  InStream:= TFileStream.Create(InName, fmOpenRead or fmShareDenyWrite);
  OutStream:= TFileStream.Create(OutName, fmCreate);
  try
    EncryptStream(InStream, OutStream, BufSize);
  finally
    InStream.Free;
    OutStream.Free;
  end;
end;

procedure TCipher.EncryptStream(InStream, OutStream: TStream; BufSize: LongWord);
const
  MIN_BUFSIZE = 4 * 1024;
  MAX_BUFSIZE = 4 * 1024 * 1024;
  DEFAULT_BUFSIZE = 16 * 1024;
  PAD_BUFSIZE = TF_MAX_CIPHER_BLOCK_SIZE;


var
  OutBufSize, DataSize: LongWord;
  Data, PData: PByte;
  N: Integer;
  Cnt: LongWord;
  Last: Boolean;

begin
  if (BufSize < MIN_BUFSIZE) or (BufSize > MAX_BUFSIZE)
    then BufSize:= DEFAULT_BUFSIZE
    else BufSize:= (BufSize + PAD_BUFSIZE - 1)
                         and not (PAD_BUFSIZE - 1);
  OutBufSize:= BufSize + PAD_BUFSIZE;
  GetMem(Data, OutBufSize);
  try
    repeat
      Cnt:= BufSize;
      PData:= Data;
      repeat
        N:= InStream.Read(PData^, Cnt);
        if N <= 0 then Break;
        Inc(PData, N);
        Dec(Cnt, N);
      until (Cnt = 0);
      Last:= Cnt > 0;
      DataSize:= BufSize - Cnt;
      Encrypt(Data^, DataSize, OutBufSize, Last);
      if DataSize > 0 then
        OutStream.WriteBuffer(Data^, DataSize);
    until Last;
  finally
    FreeMem(Data);
  end;
end;

procedure TCipher.DecryptStream(InStream, OutStream: TStream; BufSize: LongWord);
const
  MIN_BUFSIZE = 4 * 1024;
  MAX_BUFSIZE = 4 * 1024 * 1024;
  DEFAULT_BUFSIZE = 16 * 1024;
  PAD_BUFSIZE = TF_MAX_CIPHER_BLOCK_SIZE;

var
  OutBufSize, DataSize: LongWord;
  Data, PData: PByte;
  N: Integer;
  Cnt: LongWord;
  Last: Boolean;

begin
  if (BufSize < MIN_BUFSIZE) or (BufSize > MAX_BUFSIZE)
    then BufSize:= DEFAULT_BUFSIZE
    else BufSize:= (BufSize + PAD_BUFSIZE - 1)
                         and not (PAD_BUFSIZE - 1);
  OutBufSize:= BufSize + PAD_BUFSIZE;
  GetMem(Data, OutBufSize);
  try
    PData:= Data;
    Cnt:= OutBufSize;
    repeat
      repeat
        N:= InStream.Read(PData^, Cnt);
        if N <= 0 then Break;
        Inc(PData, N);
        Dec(Cnt, N);
      until (Cnt = 0);
      Last:= Cnt > 0;
      if Last then begin
        DataSize:= OutBufSize - Cnt;
      end
      else begin
        DataSize:= BufSize - Cnt;
      end;
      Decrypt(Data^, DataSize, Last);
      if DataSize > 0 then
        OutStream.WriteBuffer(Data^, DataSize);
      if Last then Break
      else begin
        Move((Data + OutBufSize - PAD_BUFSIZE)^, Data^, PAD_BUFSIZE);
        PData:= Data + PAD_BUFSIZE;
        Cnt:= BufSize;
      end;
    until False;
  finally
    FreeMem(Data);
  end;
end;

function TCipher.DecryptData(const Data: ByteArray): ByteArray;
var
  L: LongWord;

begin
  L:= Data.GetLen;
  Result:= Data.Copy;
  HResCheck(FAlgorithm.Decrypt(Result.RawData, L, True));
  Result.SetLen(L);
end;

procedure TCipher.DecryptFile(const InName, OutName: string; BufSize: LongWord);
var
  InStream, OutStream: TStream;

begin
  InStream:= TFileStream.Create(InName, fmOpenRead or fmShareDenyWrite);
  OutStream:= TFileStream.Create(OutName, fmCreate);
  try
    DecryptStream(InStream, OutStream, BufSize);
  finally
    InStream.Free;
    OutStream.Free;
  end;
end;

function TCipher.Copy: TCipher;
begin
  HResCheck(FAlgorithm.DuplicateKey(Result.FAlgorithm));
end;

class function TCipher.AlgCount: Integer;
begin
  Result:= FServer.GetCount;
end;

{
function TCipher.Decrypt(const Data: ByteArray): ByteArray;
var
  L: LongWord;

begin
  L:= Data.Len;
  Result:= ByteArray.Copy(Data);
  Decrypt(Result.RawData^, L, True);
  Result.Len:= L;
end;
}

class function TCipher.AlgName(Index: Cardinal): string;
var
  Bytes: IBytes;
  I, L: Integer;
  P: PByte;

begin
  HResCheck(FServer.GetName(Index, Bytes));
  L:= Bytes.GetLen;
  P:= Bytes.GetRawData;
  SetLength(Result, L);
  for I:= 1 to L do begin
    Result[I]:= Char(P^);
    Inc(P);
  end;
end;

class function TCipher.Salsa20: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_SALSA20, Result.FAlgorithm));
end;

class function TCipher.Salsa20(Rounds: LongWord): TCipher;
begin
  HResCheck(FServer.GetSalsa20(Rounds, Result.FAlgorithm));
end;

class function TCipher.ChaCha20: TCipher;
begin
  HResCheck(FServer.GetByAlgID(TF_ALG_CHACHA20, Result.FAlgorithm));
end;

class function TCipher.ChaCha20(Rounds: LongWord): TCipher;
begin
  HResCheck(FServer.GetChaCha20(Rounds, Result.FAlgorithm));
end;

function TCipher.SetFlags(AFlags: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @AFlags, SizeOf(AFlags)));
  Result:= Self;
end;

procedure TCipher.SetFlagsProc(const Value: LongWord);
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_FLAGS, @Value, SizeOf(Value)));
end;

function TCipher.SetIV(AIV: Pointer; AIVLen: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_IV, AIV, AIVLen));
  Result:= Self;
end;

function TCipher.SetIV(const AIV: ByteArray): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_IV, AIV.RawData, AIV.Len));
  Result:= Self;
end;

procedure TCipher.SetIVProc(const Value: ByteArray);
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_IV, Value.RawData, Value.Len));
end;

function TCipher.SetNonce(const Value: ByteArray): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_NONCE, Value.RawData, Value.Len));
  Result:= Self;
end;

function TCipher.SetNonce(const Value: UInt64): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_NONCE{_LE}, @Value, SizeOf(Value)));
  Result:= Self;
end;

procedure TCipher.SetNonceProc(const Value: ByteArray);
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_NONCE, Value.RawData, Value.Len));
end;

{
function TCipher.SetBlockNo(const Value: ByteArray): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_BLOCKNO, Value.RawData, Value.Len));
  Result:= Self;
end;

function TCipher.SetBlockNo(const Value: UInt64): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_BLOCKNO_LE, @Value, SizeOf(Value)));
  Result:= Self;
end;
}

function TCipher.Skip(Value: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_INCNO{_LE}, @Value, SizeOf(Value)));
  Result:= Self;
end;

function TCipher.Skip(Value: UInt64): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_INCNO{_LE}, @Value, SizeOf(Value)));
  Result:= Self;
end;
{
function TCipher.Skip(Value: ByteArray): TCipher;
begin
  HResCheck(FAlgorithm.SetKeyParam(TF_KP_INCNO, @Value, SizeOf(Value)));
  Result:= Self;
end;
}
function TCipher.ExpandKey(AKey: PByte; AKeyLen: LongWord): TCipher;
begin
  HResCheck(FAlgorithm.ExpandKey(AKey, AKeyLen));
  Result:= Self;
end;

function TCipher.ExpandKey(const AKey: ByteArray): TCipher;
begin
  HResCheck(FAlgorithm.ExpandKey(AKey.RawData, AKey.Len));
  Result:= Self;
end;

class operator TCipher.Explicit(AlgID: Integer): TCipher;
begin
  HResCheck(FServer.GetByAlgID(AlgID, Result.FAlgorithm));
end;

class operator TCipher.Explicit(const Name: string): TCipher;
begin
  HResCheck(FServer.GetByName(Pointer(Name), SizeOf(Char), Result.FAlgorithm));
end;

{ TKeyStream }

procedure TKeyStream.Free;
begin
  FKeyStream:= nil;
end;

function TKeyStream.IsAssigned: Boolean;
begin
  Result:= FKeyStream <> nil;
end;

function TKeyStream.KeyStream(ASize: Cardinal): ByteArray;
begin
  Result:= ByteArray.Allocate(ASize);
  HResCheck(FKeyStream.Read(Result.GetRawData, ASize));
end;

procedure TKeyStream.Burn;
begin
  FKeyStream.Burn;
end;

function TKeyStream.ExpandKey(AKey: PByte; AKeyLen: LongWord; ANonce: UInt64): TKeyStream;
begin
  HResCheck(FKeyStream.ExpandKey(AKey, AKeyLen, ANonce));
end;

class operator TKeyStream.Explicit(const Name: string): TKeyStream;
begin
  HResCheck(FServer.GetKSByName(Pointer(Name), SizeOf(Char), Result.FKeyStream));
end;

class operator TKeyStream.Explicit(AlgID: Integer): TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(AlgID, Result.FKeyStream));
end;

function TKeyStream.ExpandKey(const AKey: ByteArray; ANonce: UInt64): TKeyStream;
begin
  HResCheck(FKeyStream.ExpandKey(AKey.GetRawData, AKey.GetLen, ANonce));
  Result:= Self;
end;

function TKeyStream.Skip(AValue: Int64): TKeyStream;
begin
  HResCheck(FKeyStream.Skip(AValue));
end;

class function TKeyStream.AES: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_AES, Result.FKeyStream));
end;

class function TKeyStream.DES: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_DES, Result.FKeyStream));
end;

class function TKeyStream.TripleDES: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_3DES, Result.FKeyStream));
end;

class function TKeyStream.Salsa20: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_SALSA20, Result.FKeyStream));
end;

class function TKeyStream.Salsa20(Rounds: LongWord): TKeyStream;
begin
  HResCheck(FServer.GetKSSalsa20(Rounds, Result.FKeyStream));
end;

class function TKeyStream.ChaCha20: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_CHACHA20, Result.FKeyStream));
end;

class function TKeyStream.ChaCha20(Rounds: LongWord): TKeyStream;
begin
  HResCheck(FServer.GetKSChaCha20(Rounds, Result.FKeyStream));
end;

class function TKeyStream.RC4: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_RC4, Result.FKeyStream));
end;

class function TKeyStream.RC5(BlockSize, Rounds: LongWord): TKeyStream;
begin
  HResCheck(FServer.GetKSRC5(BlockSize, Rounds, Result.FKeyStream));
end;

class function TKeyStream.RC5: TKeyStream;
begin
  HResCheck(FServer.GetKSByAlgID(TF_ALG_RC5, Result.FKeyStream));
end;

procedure TKeyStream.Read(var Data; DataLen: LongWord);
begin
  HResCheck(FKeyStream.Read(@Data, DataLen));
end;

procedure TKeyStream.Crypt(var Data; DataLen: LongWord);
begin
  HResCheck(FKeyStream.Crypt(@Data, DataLen));
end;









{$IFNDEF TFL_DLL}
initialization
  GetCipherServer(FServer);

{$ENDIF}
end.
