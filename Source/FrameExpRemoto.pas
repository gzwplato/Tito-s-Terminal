unit FrameExpRemoto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, IDEWindowIntf, Forms, Controls, ComCtrls, LCLType,
  Menus, ActnList, ExtCtrls, StdCtrls, RegExpr, MisUtils;
const
  //índice a las imágenes
  IMG_ARCHIVO = 0;
  IMG_CARPETA = 2;

type
  { TfraExpRemoto }

  TfraExpRemoto = class(TFrame)
    acConfig: TAction;
    acEdElim: TAction;
    acArcRenom: TAction;
    acEdEdit: TAction;
    acHerEjec: TAction;
    acArcAcce: TAction;
    acArcNuevo: TAction;
    acArcNueCar: TAction;
    acVerRefres: TAction;
    ActionList1: TActionList;
    txtRuta: TEdit;
    ImageList1: TImageList;
    Label1: TLabel;
    ListView1: TListView;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    StatusBar1: TStatusBar;
    procedure acArcNueCarExecute(Sender: TObject);
    procedure acArcNuevoExecute(Sender: TObject);
    procedure acArcRenomExecute(Sender: TObject);
    procedure acConfigExecute(Sender: TObject);
    procedure acEdEditExecute(Sender: TObject);
    procedure acEdElimExecute(Sender: TObject);
    procedure acHerEjecExecute(Sender: TObject);
    procedure acVerRefresExecute(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1Edited(Sender: TObject; Item: TListItem;
      var AValue: string);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1KeyPress(Sender: TObject; var Key: char);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    lisArc: Tstringlist;  //lista de archivos
    listmp: Tstringlist;  //lista temporal
    ListDet: boolean;   //lista detallada
    MosOcul: boolean;  //mostrar archivos ocultos
    re: TRegExpr;   //motor de expresiones regulares
    procedure ActualizarSel(arc: string);
    procedure AgregarCarpAtras;
    procedure AgregarFila(lin: string; iconIndex: integer);
    procedure AgregarFilaArc(lin: string);
    procedure AgregarFilaCar(lin: string);
    procedure AgregarFilaErr(lin: string);
    procedure AgregarMensajeEspera(lin: string);
//    procedure BuscaPosicionCampos;
    procedure ConfigurarColumnasDetalladas;
    procedure ConfigurarColumnasSimple;
    { private declarations }
  public
    OnDblClickArch: procedure of object;  //doble click en archivo
    procedure Actualizar;
    //funciones de búsqueda
    function BuscarItem(nomb: string): TListItem;
    function ItemSeleccionado: TListItem;
    function SelecMultiple: boolean;
    function SelecMulTodArchivos: boolean;
    function NumSeleccionados: integer;
    constructor Create(AOwner: TComponent) ; override;
    destructor Destroy; override;
  end;

implementation
uses FormPrincipal, FormConfig, FormEditRemoto;

{$R *.lfm}

{ TfraExpRemoto }
procedure TfraExpRemoto.AgregarFila(lin: string; iconIndex: integer);
//Agrega una fila de datos a la lista de archivos
var
  it: TListItem;
begin
  if ListDet then begin
    //hay información de campos
    it := ListView1.Items.Add;
    //identifica campos
    if (re.Exec(lin)) then begin
      //encontró los campos
      it.Caption:=re.Match[7];  //nombre
      it.SubItems.Add(re.Match[6]); //fecha
      it.SubItems.Add(re.Match[5]); //tamaño
      it.SubItems.Add(re.Match[1]); //atributos
      it.SubItems.Add(re.Match[3]); //propietario
      it.SubItems.Add(re.Match[4]); //grupo
      it.SubItems.Add(re.Match[2]); //enlaces
      it.ImageIndex:=iconIndex;
    end else begin
      //no pudo extraer los campos
      it.Caption:='???';
      it.ImageIndex:=3;  //error
    end;
  end else begin
    it := ListView1.Items.Add;
    it.Caption:=lin;
    it.ImageIndex:=iconIndex;
  end;
end;
procedure TfraExpRemoto.AgregarFilaArc(lin: string); // archivo
begin
  AgregarFila(lin, IMG_ARCHIVO)
end;
procedure TfraExpRemoto.AgregarFilaCar(lin: string);  //carpeta
begin
  AgregarFila(lin,IMG_CARPETA)
end;

procedure TfraExpRemoto.AgregarFilaErr(lin: string); //Mensaje de error
var
  it: TListItem;
begin
  it := ListView1.Items.Add;
  it.Caption:=lin;
  it.ImageIndex:=3;
end;
procedure TfraExpRemoto.AgregarMensajeEspera(lin: string); //Mensaje en espera
var
  it: TListItem;
begin
  ListView1.Items.Clear;  //limpia todo lo que había antes
  it := ListView1.Items.Add;
  it.Caption:=lin;
  it.ImageIndex:=4;
end;
procedure TfraExpRemoto.AgregarCarpAtras; //Carpeta ".."
var
  it: TListItem;
begin
  it := ListView1.Items.Add;
  it.Caption:='..';
  it.ImageIndex:=2;
end;

procedure TfraExpRemoto.ConfigurarColumnasSimple;
var
  Col: TListColumn;
begin
  ListView1.Columns.Clear;
  Col := ListView1.Columns.Add;
  Col.Caption := 'Nombre';
  Col.Alignment := taLeftJustify;
  Col.Width := 200;
end;
procedure TfraExpRemoto.ConfigurarColumnasDetalladas;
var
  Col: TListColumn;
begin
  ListView1.Columns.Clear;
  Col := ListView1.Columns.Add;
  Col.Caption := 'Nombre';
  Col.Alignment := taLeftJustify;
  Col.Width := 160;

  Col := ListView1.Columns.Add;
  Col.Caption := 'Fecha Modificación';
  Col.Alignment := taLeftJustify;
  Col.Width := 100;

  Col := ListView1.Columns.Add;
  Col.Caption := 'Tamaño';
  Col.Alignment := taRightJustify;
  Col.Width := 80;

  Col := ListView1.Columns.Add;
  Col.Caption := 'Atributos';
  Col.Alignment := taLeftJustify;
  Col.Width := 90;

  Col := ListView1.Columns.Add;
  Col.Caption := 'Propietario';
  Col.Alignment := taLeftJustify;
  Col.Width := 80;

  Col := ListView1.Columns.Add;
  Col.Caption := 'Grupo';
  Col.Alignment := taLeftJustify;
  Col.Width := 80;

  Col := ListView1.Columns.Add;
  Col.Caption := 'Enlaces asociados';
  Col.Alignment := taRightJustify;
  Col.Width := 40;
end;
function TfraExpRemoto.BuscarItem(nomb: string): TListItem;
//Busca un ítem por nombre
var
  it: TListItem;
begin
  Result:= nil;
  for it in listView1.Items do
    if it.Caption = nomb then exit(it);
end;
function TfraExpRemoto.ItemSeleccionado: TListItem;
//Devuelve el ítem seleccionado
begin
  Result := nil;
  if ListView1.ItemIndex<>-1 then
    Result := listView1.Items[ListView1.ItemIndex];
end;
function TfraExpRemoto.SelecMultiple: boolean;
//Indica si hay selección múltiple
var
  it: TListItem;
  n: Integer;
begin
  n := 0;
  Result := false;
  for it in ListView1.Items do begin
    if it.Selected then begin
       inc(n); if n>1 then exit(true);
    end;
  end;
end;
function TfraExpRemoto.SelecMulTodArchivos: boolean;
//Indica si la selección incluye solamente archivos
var
  it: TListItem;
begin
  Result := true;  //se asume que todos lo son
  for it in ListView1.Items do if it.Selected then begin
    if it.ImageIndex <> IMG_ARCHIVO then begin
       exit(false);   //hay al menos uno que no.
    end;
  end;
end;
function TfraExpRemoto.NumSeleccionados: integer;
var
  it: TListItem;
begin
  Result := 0;
  for it in ListView1.Items do begin
    if it.Selected then  inc(Result);
  end;
end;

procedure TfraExpRemoto.Actualizar;
//actualiza la lista de archivos de la ruta actual
var
  i: Integer;
  MsjErr : string;
  n: Integer;
  fil: String;
begin
  if not frmPrincipal.ConexDisponible then begin
    msgexc('No hay conexión disponible.');
    ListView1.Items.Clear;
    AgregarFilaErr('Error leyendo datos.');
    exit;
  end;
  AgregarMensajeEspera('Leyendo...');   //sería bueno mostrar una animación
  //actualiza lista de archivos
  ListDet := config.fcExpRem.ListDet;  //lee bandera
  MosOcul := config.fcExpRem.MosOcul;
  if config.fcExpRem.MosRut then begin  //debe actualizar ruta
    frmPrincipal.EnviarComando('pwd',listmp); //lee ruta
    txtRuta.Text:= listmp.Text;
    Panel1.Visible:=true;  //muestra panel de ruta
  end else begin
    Panel1.Visible:=false;
  end;
  if ListDet then begin
    ConfigurarColumnasDetalladas;
    if MosOcul then MsjErr := frmPrincipal.EnviarComando('ls -la',lisArc)
    else MsjErr := frmPrincipal.EnviarComando('ls -l',lisArc);
  end else begin
    ConfigurarColumnasSimple;
    if MosOcul then MsjErr := frmPrincipal.EnviarComando('ls -1a',lisArc)
    else MsjErr := frmPrincipal.EnviarComando('ls -1',lisArc);
  end;
  if MsjErr <> '' then begin
    ListView1.Items.Clear;
    AgregarFilaErr('Error leyendo datos.');
  end else begin  //no hubo MsjErr
    ListView1.Items.Clear;
    if not MosOcul then AgregarCarpAtras;  //para que se pueda retroceder
    n := 0;  //contador
    if ListDet then begin  //////lista detallada
      ListView1.BeginUpdate;
      //agrega primero las carpetas
      for fil in lisArc do begin
        if length(fil) > 20 then begin  //filtra TOTAL: ####
          if fil[1] = 'd' then begin AgregarFilaCar(fil); inc(n); end;
        end;
      end;
      //agrega luego los archivos
      for fil in lisArc do begin
        if length(fil) > 20 then begin  //filtra TOTAL: ####
          if fil[1] <> 'd' then begin AgregarFilaArc(fil); inc(n); end;
        end;
      end;
      ListView1.EndUpdate;
    end else begin  //////////lista simple
      for i:=0 to lisArc.Count-1 do begin
        AgregarFilaArc(lisArc[i]);
        inc(n);
      end;
    end;
    StatusBar1.Panels[0].Text := IntToStr(n) + ' archivos leidos.';
  end;
end;
procedure TfraExpRemoto.ActualizarSel(arc: string);
//Actualiza la lista de archivos y selecciona un archivo o carpeta
var
  it: TListItem;
begin
  Actualizar;
  it := BuscarItem(arc);
  if it = nil then exit;
  it.Selected:=true;
end;

constructor TfraExpRemoto.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //prepara lista
  ListView1.RowSelect:=true;
  ListView1.MultiSelect:=true;
  ListView1.ViewStyle:=vsReport;
  ListView1.ReadOnly:=true;  //para que no se edite con doble click
  ListView1.OnEdited:=@ListView1Edited;

  lisArc := TStringlist.Create;  //crea lista de archivos
  listmp := TStringlist.Create;  //crea lista de archivos
  re := TRegExpr.Create;
  //define expresión regular para extraer campos de la lista de archivos
  re.Expression := '^(\S+)\x20+(\d+)\x20+(\w+)\x20+(\w+)\x20+(\d+)\x20+'+  //primeros campos
  '(\w{3}\x20+\d+\x20+\S+|\d+\x20+\w{3}\x20+\S+)\x20+(.+)';  //fecha y nombre

end;
destructor TfraExpRemoto.Destroy;
begin
  re.Free;
  lisArc.Destroy;
  listmp.Destroy;
  inherited Destroy;
end;

////////////////////// acciones ///////////////////
procedure TfraExpRemoto.acVerRefresExecute(Sender: TObject);
begin
  Actualizar;
end;
procedure TfraExpRemoto.ListView1DblClick(Sender: TObject);
var
  it: TListItem;
begin
  if ListView1.ItemIndex<>-1 then begin
    //doble click en ítem
    it := listView1.Items[ListView1.ItemIndex];
    if it.ImageIndex = IMG_CARPETA then begin //es carpeta
      frmPrincipal.EnviarComando('cd "'+it.Caption+'"', listmp);
      if trim(listmp.Text)<>'' then msgErr(listmp.Text);
      ActualizarSel('..');
    end else begin  //es archivo
      //dispara evento
      if OnDblClickArch<>nil then OnDblClickArch;
    end;
  end;
end;
procedure TfraExpRemoto.ListView1Edited(Sender: TObject; Item: TListItem;
  var AValue: string);
//Evento porducido después de editar un nombre
begin
  if Item.Caption <> Avalue then begin
    frmPrincipal.EnviarComando('mv "'+ Item.Caption + '" "'+ Avalue+'"', listmp);
    if trim(listmp.Text)<>'' then msgErr(listmp.Text);
    if config.fcExpRem.RefDesp then ActualizarSel('Avalue');
  end;
end;

procedure TfraExpRemoto.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_DELETE then begin
    acEdElimExecute(self);
  end;
end;

procedure TfraExpRemoto.ListView1KeyPress(Sender: TObject; var Key: char);
var
  it: TListItem;
begin
  if Key = #8 then begin  //backspace
    frmPrincipal.EnviarComando('cd ..', listmp);
    if trim(listmp.Text)<>'' then msgErr(listmp.Text);
    ActualizarSel('..');
  end;
  if key = #13 then begin
    ListView1DblClick(self);
  end;
end;

procedure TfraExpRemoto.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  StatusBar1.Panels[1].Text:=IntToStr(NumSeleccionados)+' elementos Selecionados.';
end;

procedure TfraExpRemoto.acArcNuevoExecute(Sender: TObject); //nuevo archivo
var
  nom: String;
  n: Integer;
begin
  //Genera nuevo nombre
  nom := 'NuevoArchivo';
  n := 1;
  while BuscarItem(nom)<>nil do
    begin
      inc(n); nom := 'NuevoArchivo' + IntToStr(n);
    end;
  frmPrincipal.EnviarComando('echo "" >'+ nom, listmp);
  if config.fcExpRem.RefDesp then ActualizarSel(nom);
  self.SetFocus;
end;
procedure TfraExpRemoto.acArcRenomExecute(Sender: TObject);  //renombrar
var
  it: TListItem;
  anterior: String;
begin
  it := ItemSeleccionado;
  if it = nil then exit;
  ListView1.ReadOnly:=false;  //para editar
  anterior := it.Caption;
  it.EditCaption; //inicia edición
  ListView1.ReadOnly:=true;  //para que no se edite con doble click
end;
procedure TfraExpRemoto.acArcNueCarExecute(Sender: TObject);  //nueva carpeta
var
  nom: String;
  n: Integer;
begin
  //Genera nuevo nombre
  nom := 'NuevaCarpeta';
  n := 1;
  while BuscarItem(nom)<>nil do
    begin
      inc(n); nom := 'NuevaCarpeta' + IntToStr(n);
    end;
  frmPrincipal.EnviarComando('mkdir '+nom, listmp);
  if config.fcExpRem.RefDesp then ActualizarSel(nom);
end;
procedure TfraExpRemoto.acEdElimExecute(Sender: TObject);  //eliminar
var
  it: TListItem;
begin
  it := ItemSeleccionado;
  if it = nil then exit;
  if SelecMultiple then begin  //selección múltiple
    if SelecMulTodArchivos then begin //todos son archivos
      if MsgYesNo('¿Eliminar '+ IntToStr(NumSeleccionados) +' archivos?') = 1 then begin
        for it in ListView1.Items do if it.Selected then begin
          frmPrincipal.EnviarComando('rm "' + it.Caption+'"', listmp);
        end;
        if config.fcExpRem.RefDesp then Actualizar;
      end;
    end else begin  //hay carpetas entre los seleccionados
       MsgExc('No se puede eliminar carpetas y archivos juntos');
    end;
  end else begin  //selección simple
    if it.ImageIndex = IMG_CARPETA then begin //es carpeta
      if MsgYesNo('¿Eliminar carpeta: '+ it.Caption +'?') = 1 then begin
        frmPrincipal.EnviarComando('rmdir '+it.Caption, listmp);
        if trim(listmp.Text)<>'' then msgErr(listmp.Text);
        if config.fcExpRem.RefDesp then Actualizar;
      end;
    end else begin  //es archivo
      if MsgYesNo('¿Eliminar archivo: '+ it.Caption +'?') = 1 then begin
        frmPrincipal.EnviarComando('rm "' + it.Caption+'"', listmp);
        if trim(listmp.Text)<>'' then msgErr(listmp.Text);
        if config.fcExpRem.RefDesp then Actualizar;
      end;
    end;
  end;
end;
procedure TfraExpRemoto.acHerEjecExecute(Sender: TObject); //ejecutar
var
  it: TListItem;
begin
  it := ItemSeleccionado;
  if it = nil then exit;
  frmPrincipal.EnviarComando(it.Caption, listmp);
end;
procedure TfraExpRemoto.acEdEditExecute(Sender: TObject);  //editar archivo
var
  it: TListItem;
begin
  it := ItemSeleccionado;
  if it = nil then exit;
  if it.ImageIndex = IMG_CARPETA then begin //es carpeta
//    frmPrincipal.EnviarComando('cd '+it.Caption, listmp);
//    if config.fcExpRem.RefDesp then Actualizar;
  end else begin  //es archivo
    frmEditRemoto.AbrirRemoto(it.Caption);
  end;
end;
procedure TfraExpRemoto.acConfigExecute(Sender: TObject);
begin
  config.Configurar('Otros');
end;

end.
