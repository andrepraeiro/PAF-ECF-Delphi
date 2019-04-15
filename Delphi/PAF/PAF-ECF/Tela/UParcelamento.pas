{ *******************************************************************************
  Title: T2TiPDV
  Description: Gera Parcelas para o Contas a Receber.

  The MIT License

  Copyright: Copyright (C) 2012 Albert Eije

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation
  files (the "Software"), to deal in the Software without
  restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.

  The author may be contacted at:
  alberteije@gmail.com

  @author Albert Eije
  @version 1.0
  ******************************************************************************* }
unit UParcelamento;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, UBase,
  Dialogs, StdCtrls, ExtCtrls, pngimage, JvExStdCtrls,
  Buttons, JvExButtons, JvBitBtn, Grids, DBGrids, JvExDBGrids, JvDBGrid, JvEdit,
  JvValidateEdit, JvToolEdit, Mask, JvExMask, JvSpin, JvBaseEdits, DB, DBClient,
  JvComponentBase, JvEnterTab, JvDBControls, Generics.Collections, JvExControls,
  JvSpeedButton;

type
  TFParcelamento = class(TFBase)
    botaoConfirma: TJvBitBtn;
    Image1: TImage;
    GroupBox1: TGroupBox;
    editNome: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    editCPF: TEdit;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    JvDBGrid1: TJvDBGrid;
    qtdParcelas: TJvSpinEdit;
    editVencimento: TJvDateEdit;
    editValorVenda: TJvCalcEdit;
    editValorRecebido: TJvCalcEdit;
    editValorParcelar: TJvCalcEdit;
    Panel1: TPanel;
    JvEnterAsTab1: TJvEnterAsTab;
    CDSParcela: TClientDataSet;
    DSParcela: TDataSource;
    CDSParcelaParcela: TIntegerField;
    CDSParcelaVencimento: TDateField;
    CDSParcelaValor: TCurrencyField;
    jvDBDateEdit1: TJvDBDateEdit;
    botaoLocalizaCliente: TSpeedButton;
    editDesconto: TJvCalcEdit;
    lblDesconto: TLabel;
    botaoCancela: TJvSpeedButton;
    procedure JvDBGrid1ColExit(Sender: TObject);
    procedure JvDBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure JvDBGrid1KeyPress(Sender: TObject; var Key: Char);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure botaoConfirmaClick(Sender: TObject);
    procedure JvDBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure botaoLocalizaClienteClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CalculaParcelas;
    procedure qtdParcelasChange(Sender: TObject);
    procedure editVencimentoChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FParcelamento: TFParcelamento;
  confirmou: Boolean;

implementation

uses UCaixa, ContasParcelasVO, ContasPagarReceberVO, Controller,
  Biblioteca, UIdentificaCliente, VendaController;
{$R *.dfm}

(*
  ALTERAR - Adaptar para novo Controller
*)

procedure TFParcelamento.botaoConfirmaClick(Sender: TObject);
var
  Total, ValoraParcelar: Currency;
  ParcelaCabecalho: TContasPagarReceberVO;
  ParcelaDetalhe: TContasParcelasVO;
  ListaParcelaDetalhe: TObjectList<TContasParcelasVO>;
  Identificacao: String;
begin
  if Sessao.VendaAtual.IdCliente < 1 then
  begin
    Application.MessageBox('Escolha um cliente para Parcelar!', 'Informa��o do Sistema', MB_OK + MB_ICONINFORMATION);
    Abort;
  end;
  Identificacao := 'E' + IntToStr(Sessao.Configuracao.IdEcfEmpresa) + 'X' + IntToStr(Sessao.Configuracao.IdEcfCaixa) + 'V' + DevolveInteiro(FCaixa.edtNVenda.Caption) + 'C' + DevolveInteiro(FCaixa.edtCOO.Caption);

  Total := 0;
  ValoraParcelar := StrToFloat(editValorParcelar.Text);

  CDSParcela.DisableControls;
  CDSParcela.First;

  while not CDSParcela.Eof do
  begin
    Total := Total + CDSParcelaValor.AsFloat;
    CDSParcela.Next;
  end;
  CDSParcela.EnableControls;

  if (Total = ValoraParcelar) then
  begin
    try
      ParcelaCabecalho := TContasPagarReceberVO.Create;
      ParcelaCabecalho.IdEcfVendaCabecalho := Sessao.VendaAtual.Id;
      ParcelaCabecalho.IdPlanoContas := 1;
      ParcelaCabecalho.IdTipoDocumento := 1;
      ParcelaCabecalho.IdPessoa := Sessao.VendaAtual.IdCliente;
      ParcelaCabecalho.Tipo := 'R';
      ParcelaCabecalho.NumeroDocumento := Identificacao + 'Q' + qtdParcelas.Text;
      ParcelaCabecalho.Valor := Total;
//      ParcelaCabecalho.DataLancamento := UCaixa.VendaCabecalho.DataVenda;
//      ParcelaCabecalho.PrimeiroVencimento := DataParaTexto(editVencimento.Date);
      ParcelaCabecalho.NaturezaLancamento := 'S';
      ParcelaCabecalho.QuantidadeParcela := qtdParcelas.AsInteger;
      ParcelaCabecalho.IdEcfVendaCabecalho := Sessao.VendaAtual.Id;
      ParcelaCabecalho.IdPessoa := Sessao.VendaAtual.IdCliente;
//      ParcelaCabecalho.DataLancamento := UCaixa.VendaCabecalho.DataVenda;
      ParcelaCabecalho.Tipo := 'R';
      ParcelaCabecalho.Valor := Total;
      ParcelaCabecalho.NaturezaLancamento := 'S';
//   ALTERAR   ParcelaCabecalho := TParcelaController.InserirCabecalho(ParcelaCabecalho);
      ListaParcelaDetalhe := TObjectList<TContasParcelasVO>.Create;

      CDSParcela.DisableControls;
      CDSParcela.First;

      while not CDSParcela.Eof do
      begin
        ParcelaDetalhe := TContasParcelasVO.Create;
        ParcelaDetalhe.IdContasPagarReceber := ParcelaCabecalho.Id;
//        ParcelaDetalhe.DataEmissao := UCaixa.VendaCabecalho.DataVenda;
//        ParcelaDetalhe.DataVencimento := DataParaTexto(CDSParcelaVencimento.AsDateTime);
        ParcelaDetalhe.NumeroParcela := StrToInt(CDSParcelaParcela.Text);
        ParcelaDetalhe.Valor := StrToFloat(CDSParcelaValor.Text);
        ParcelaDetalhe.TaxaJuros := 0;
        ParcelaDetalhe.TaxaMulta := 0;
        ParcelaDetalhe.TaxaDesconto := 0;
        ParcelaDetalhe.ValorJuros := 0;
        ParcelaDetalhe.ValorMulta := 0;
        ParcelaDetalhe.ValorDesconto := 0;
        ParcelaDetalhe.TotalParcela := StrToFloat(CDSParcelaValor.Text);
        ParcelaDetalhe.Historico := '';
        ParcelaDetalhe.Situacao := 'A';
        ListaParcelaDetalhe.Add(ParcelaDetalhe);
        CDSParcela.Next;
      end;

      CDSParcela.EnableControls;

//    ALTERAR  TParcelaController.InserirDetalhe(ListaParcelaDetalhe);
      confirmou := True;
    finally
      ParcelaCabecalho.Free;
      ListaParcelaDetalhe.Free;
    end;
    Close;
  end
  else
    Application.MessageBox('A soma das Parcelas difere do valor a parcelar!', 'Informa��o do Sistema', MB_OK + MB_ICONINFORMATION);
end;

procedure TFParcelamento.CalculaParcelas;
var
  x, QtdPar: Integer;
  Vencimento: TDateTime;
  ValorTotal, ValorParcela, Resto: Real;
begin
  if CDSParcela.Active then
    CDSParcela.EmptyDataSet
  else
    CDSParcela.CreateDataSet;

  QtdPar := StrToInt(qtdParcelas.Text);
  ValorTotal := StrToFloat(editValorParcelar.Text);
  ValorParcela := Round(ValorTotal / QtdPar);
  Resto := (ValorTotal - (ValorParcela * QtdPar));

  Vencimento := editVencimento.Date;

  for x := 1 To QtdPar do
  begin
    CDSParcela.Append;
    CDSParcelaParcela.AsInteger := x;
    CDSParcelaVencimento.AsDateTime := Vencimento;
    if x = 1 then
      CDSParcelaValor.AsFloat := ValorParcela + Resto
    else
      CDSParcelaValor.AsFloat := ValorParcela;
    CDSParcela.Post;
    Vencimento := IncMonth(Vencimento);
  end;
  CDSParcela.Edit;
end;

procedure TFParcelamento.editVencimentoChange(Sender: TObject);
begin
  CalculaParcelas;
end;

procedure TFParcelamento.FormActivate(Sender: TObject);
begin
  Color := StringToColor(Sessao.Configuracao.CorJanelasInternas);
  editVencimento.Date := Date + 30;
  qtdParcelas.SetFocus;
end;

procedure TFParcelamento.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if confirmou then
    ModalResult := MROK;
end;

procedure TFParcelamento.FormCreate(Sender: TObject);
begin
  confirmou := False;
  qtdParcelas.MaxValue := Sessao.Configuracao.QuantidadeMaximaParcela;
end;

procedure TFParcelamento.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    botaoCancela.Click;
  if (Key = 112) then
    botaoLocalizaCliente.Click;
end;

procedure TFParcelamento.JvDBGrid1ColExit(Sender: TObject);
begin
  if JvDBGrid1.SelectedField.FieldName = 'Vencimento' then
    jvDBDateEdit1.Visible := False;
end;

procedure TFParcelamento.JvDBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if (gdFocused in State) then
  begin
    if (Column.Field.FieldName = 'Vencimento') then
    begin
      with jvDBDateEdit1 do
      begin
        Left := Rect.Left + JvDBGrid1.Left + 1;
        Top := Rect.Top + JvDBGrid1.Top + 1;
        Width := Rect.Right - Rect.Left + 2;
        Width := Rect.Right - Rect.Left + 2;
        Height := Rect.Bottom - Rect.Top + 2;
        Visible := True;
      end;
    end;
  end;
end;

procedure TFParcelamento.JvDBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  qt, Total, valorant, prest, Resto: Real;
  Bookmark: TBookmark;
begin
  if (Key = vk_return) then
  begin
    Total := 0;
    prest := 0;
    qt := 0;
    valorant := 0;

    CDSParcela.Post;

    CDSParcela.DisableControls;

    // quantas parcelas ainda faltam
    Bookmark := CDSParcela.GetBookmark;
    while not CDSParcela.Eof do
    begin
      qt := qt + 1;
      CDSParcela.Next;
    end;
    qt := qt - 1;
    CDSParcela.GotoBookmark(Bookmark);

    // pega o saldo das parcelas anteriores
    Bookmark := CDSParcela.GetBookmark;
    while not CDSParcela.bof do
    begin
      valorant := valorant + CDSParcela.Fieldbyname('Valor').AsFloat;
      CDSParcela.prior;
    end;

    CDSParcela.GotoBookmark(Bookmark);
    Bookmark := CDSParcela.GetBookmark;
    Total := editValorParcelar.Value - valorant;

    If (Total >= 0) then
    begin
      if (Total > 0) and (qt > 0) then
      begin
        prest := Round(Total / qt);
        Resto := (Total - (prest * qt));
        CDSParcela.Edit;
        CDSParcela.Fieldbyname('VALOR').AsFloat := CDSParcela.Fieldbyname('VALOR').AsFloat + Resto;
        CDSParcela.Post;
      end;

      CDSParcela.Next;

      while not CDSParcela.Eof do
      begin
        CDSParcela.Edit;
        CDSParcela.Fieldbyname('VALOR').AsFloat := prest;
        CDSParcela.Post;
        CDSParcela.Next;
      end;
      CDSParcela.GotoBookmark(Bookmark);
    end
    else
    begin
      Application.MessageBox('O Valor Informado � Inv�lido!', 'Informa��o do Sistema', MB_OK + MB_ICONINFORMATION);
    end;
    CDSParcela.EnableControls;
    CDSParcela.Edit;
  end;
end;

procedure TFParcelamento.JvDBGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = Chr(9)) then
    Exit;

  if (JvDBGrid1.SelectedField.FieldName = 'Vencimento') then
  begin
    jvDBDateEdit1.SetFocus;
    SendMessage(jvDBDateEdit1.Handle, WM_Char, Word(Key), 0);
  end
end;

procedure TFParcelamento.qtdParcelasChange(Sender: TObject);
begin
  CalculaParcelas;
end;

procedure TFParcelamento.botaoLocalizaClienteClick(Sender: TObject);
begin
  Application.CreateForm(TFIdentificaCliente, FIdentificaCliente);
  FIdentificaCliente.ShowModal;
  (*
  if trim(Sessao.VendaAtual.ClienteVO.Nome) <> '' then
  begin
    editNome.Text := Sessao.VendaAtual.ClienteVO.Nome;
    editCPF.Text := Sessao.VendaAtual.ClienteVO.CpfCnpj;
    Sessao.VendaAtual.IdCliente := Sessao.VendaAtual.ClienteVO.Id;
    //Altera Cliente na Venda
    TController.ExecutarMetodo('VendaController.TVendaController', 'Altera', [Sessao.VendaAtual], 'POST', 'Boolean');
  end;
  *)
end;

end.