#include "string_support.bi"
#include "chars.bi"
#include "file.bi"

'====================================================================
Type HANDLES
	StdOut As Long
	StdIn As Long
	StdErr As Long
End Type

Type PARAMS_
	UserName As String
	ShowInfoLabels As Boolean
End Type

'====================================================================
Declare Sub Main()
Declare Function OpenHandles(ByRef h As HANDLES) As Boolean
Declare Sub CloseHandles(ByRef h As HANDLES)
Declare Sub FillParams(ByRef Params As PARAMS_)
Declare Function GetFileContents(ByVal FileName As String) As String
Declare Function GetRequestLine(ByRef h As HANDLES) As String
Declare Function EscapeText(ByVal TXT As String) As String
Declare Function GetResponseBlock(ByVal Request As String, ByRef Params As PARAMS_) As String
Declare Function GetResponseBlock_All(ByRef Params As PARAMS_) As String
Declare Function GetResponseBlock_User(ByRef Params As PARAMS_) As String

'====================================================================
Main()

'====================================================================
Public Sub Main()
	Dim Params As PARAMS_
	Dim h As HANDLES
	Dim Request As String
	Dim Response As String
	
	' Debug!
	'Shell "export"
	'Shell "whoami"
	'Shell "ls -lah >> /etc/finger/contact.txt"
	'Exit Sub
	
	' Открываем потоки...
	If Not OpenHandles(h) Then
		'Print "AN ERROR!!!"
		Exit Sub
	End If
	
	' Debug!
	'Print Environ("PATH")
	
	' Будем игнорировать любые ошибки тут...
	FillParams Params
	
	' Читаем запрос...
	Request = GetRequestLine(h)
	Request = Request & CRLF
	
	' В лог отправляем запрос...
	Print #h.StdErr, "Received query: """ & EscapeText(Request) & """"
	'Print #h.StdErr, _
	'	"Running on user: " & _
	'	EscapeText(Environ("LOGNAME")) & _
	'	" [ " & EscapeText(Environ("HOME")) & " ]"
	
	' Получаем ответ...
	Response = GetResponseBlock(Request, Params)
	
	' Debug!
	'Print #h.StdErr, "Response size: " & Len(Response) & " bytes"
	
	' Пишем ответ клиенту...
	Print #h.StdOut, Response;
	
	' Debug!
	'Print #h.StdErr, "Response sent to stdout..."
	
	' Закрываем потоки...
	CloseHandles h
	
	' Debug!
	'Print #h.StdErr, "Handles are closed..."
End Sub

'====================================================================
Public Function OpenHandles(ByRef h As HANDLES) As Boolean
	On Error GoTo hError
	
	h.StdOut = FreeFile
	Open Cons For Output As #h.StdOut
	
	h.StdIn = FreeFile
	Open Cons For Input As #h.StdIn
	
	h.StdErr = FreeFile
	Open Err For Output As #h.StdErr
	
	' Debug!
	'Dim hFile As Long
	'Open "invalid""file.dat" For Output As #hFile
	
	Return True
hError:
	Return False
End Function

'====================================================================
Public Sub CloseHandles(ByRef h As HANDLES)
	Close #h.StdOut
	Close #h.StdIn
	Close #h.StdErr
End Sub

'====================================================================
Private Sub FillParams(ByRef Params As PARAMS_)
	Dim TXT As String
	
	Params.UserName = Environ("FINGER_NAME")
	If Params.UserName = "" Then Params.UserName = "anonymous"
	
	' По умолчанию - True. Если это не строго определённые 
	' значения, то - True. Так-то...
	TXT = Environ("FINGER_INFO_LABELS")
	TXT = Trim(UCase(TXT))
	
	Select Case TXT
		Case "FALSE", "0", "NO"
			Params.ShowInfoLabels = False
		Case Else
			Params.ShowInfoLabels = True
	End Select
End Sub

'====================================================================
Private Function GetFileContents(ByVal FileName As String) As String
	Dim hFile As Long
	Dim Text As String
	Dim TXT As String
	
	On Error GoTo hError
	
	' Сразу возвращаем пустоту...
	If FileName = "" Then Return ""
	
	' Пытаемся читать файл...
	hFile = FreeFile
	Open FileName For Input As #hFile
		'Do While Not EOF(hFile)
		'	Line Input #hFile, TXT
		'	Text = Text & TXT
		'	If Not EOF(hFile) Then _
		'		Text = Text & CRLF
		'Loop
		
		Text = Input(LOF(hFile), #hFile)
	Close #hFile
	
	' Возвращаем полученное!
	Return Text
	
hError:
	Close #hFile
	Return ""
End Function

'====================================================================
Private Function GetRequestLine(ByRef h As HANDLES) As String
	Dim TXT As String
	Dim zTXT As ZString Ptr
	Dim TMP As Long
	
	Const MAX_BUFFER = 100
	
	' Только безопасное подмножество...
	'TXT = Input(MAX_BUFFER, #h.StdIn)
	
	' Если использовать предыдущий вариант, и текста прилетит 
	' меньше, чем указано в буфере, то дальше работа с потоками 
	' будет очень странной, например, запись в h.StdOut не будет 
	' работать. Точнее, всё будет прекрасно работать в тесте 
	' в консоли при передаче текста через echo, но при запуске 
	' в systemd, начнутся чудеса. Скажем, она не получит 
	' вывод программы вообще. Программа успешно отработает, 
	' завершается, systemd пишет в лог, что всё завершилось, 
	' но сокет не закрывает. И finger клиент тоже висит.
	' И закрытие stdin заранее тоже не поможет. А если его ещё 
	' и два раза закрыть, то программа даже на Ctrl+C 
	' реагировать не будет. FileFlush() тоже ничем не поможет. 
	' Думаю, что это какой-то скрытый баг Input(). Поэтому 
	' Input() - не вариант.
	' Line Input, с другой стороны, не безопасен, однако, во 
	' FreeBasic 1.10.0 появился второй вариант функции, который 
	' сделан через задницу, но работает как надо. Поэтому ниже 
	' используем именно его. Нет, передать String туда нельзя, 
	' только указатель на ZString.
	zTXT = CAllocate(MAX_BUFFER + 10, SizeOf(ZString))
	Line Input #h.StdIn, *zTXT, MAX_BUFFER
	TXT = *zTXT
	Deallocate(zTXT)
	
	' Оставляем только первую строку...
	TMP = InStr(TXT, CR)
	If TMP > 0 Then TXT = Left(TXT, TMP - 1)
	
	TMP = InStr(TXT, LF)
	If TMP > 0 Then TXT = Left(TXT, TMP - 1)
	
	' Возвращаем...
	Return TXT
End Function

'====================================================================
' Странное разделение строк на слэш и символ сделано для того, чтобы 
' при включении ворнингов компилятор на это не жаловался...
'====================================================================
Private Function EscapeText(ByVal TXT As String) As String
	Dim TMP As Long
	Dim TXT2 As String
	Dim Ch As String
	
	For TMP = 1 To Len(TXT)
		Ch = Mid(TXT, TMP, 1)
		Select Case Ch
			Case NUL:   Ch = "\" & "0"
			Case CR:    Ch = "\" & "r"
			Case LF:    Ch = "\" & "n"
			Case A_TAB: Ch = "\" & "t"
			Case V_TAB: Ch = "\" & "v"
			Case BS:    Ch = "\" & "b"
			Case FF:    Ch = "\" & "f"
			Case BEL:   Ch = "\" & "a"
		End Select
		TXT2 = TXT2 & Ch
	Next TMP
	
	Return TXT2
End Function

'====================================================================
Private Function GetResponseBlock(ByVal Request As String, _
                                  ByRef Params As PARAMS_) As String
	Dim WideMode As Boolean = False
	
	' Зачищаем запрос. Пробел в конце добавляем чтобы удобнее 
	' было "/w" ловить...
	Request = Trim(Request)
	If Right(Request, 2) = CRLF Then _
		Request = Left(Request, Len(Request) - 2)
	Request = Request & " "
	
	' Debug!
	'Print """" & EscapeText(Request) & """"
	
	' Проверяем и выкидываем "/w"...
	If UCase(Left(Request, 3)) = "/W " Then
		WideMode = True
		Request = Mid(Request, 4)
	End If
	
	' Убираем пробелы, которые ранее могли добавиться или 
	' появиться...
	Request = Trim(Request)
	
	' Debug!
	'Print """" & EscapeText(Request) & """"
	
	' Если в тексте есть пробелы, то нафиг...
	If InStr(Request, " ") > 0 Then _
		Return "Invalid Finger query" & CRLF
	
	' Если в тексте есть собака, то думаем, что там хост 
	' указан...
	If InStr(Request, "@") > 0 Then _
		Return "Forwarding is not allowed" & CRLF
	
	' А теперь проверяем, что там прилетело...
	Select Case LCase(Request)
		Case ""
			Return GetResponseBlock_All(Params)
		Case Params.UserName
			Return GetResponseBlock_User(Params)
		Case Else
			Return "User not found" & CRLF
	End Select
End Function

'====================================================================
Private Function GetResponseBlock_All(ByRef Params As PARAMS_) As String
	Return "There is only one user on this server: " & Params.UserName & CRLF
End Function

'====================================================================
Private Function GetResponseBlock_User(ByRef Params As PARAMS_) As String
	Dim ContactText As String
	Dim ProjectText As String
	Dim PlanText As String
	Dim TXT As String
	
	ContactText = GetFileContents(Environ("FINGER_CONTACT"))
	ProjectText = GetFileContents(Environ("FINGER_PROJECT"))
	PlanText = GetFileContents(Environ("FINGER_PLAN"))
	
	ContactText = FixCRLF(ContactText)
	ProjectText = FixCRLF(ProjectText)
	PlanText = FixCRLF(PlanText)
	
	If ContactText = "" Then
		TXT = TXT & "No contact." & CRLF
	Else
		TXT = TXT & ContactText & CRLF
	End If
	
	If ProjectText = "" Then
		TXT = TXT & "No project." & CRLF
	Else
		If Params.ShowInfoLabels Then _
			TXT = TXT & "Project:" & CRLF
		TXT = TXT & ProjectText & CRLF
	End If
	
	If PlanText = "" Then
		TXT = TXT & "No plan." & CRLF
	Else
		If Params.ShowInfoLabels Then _
			TXT = TXT & "Plan: "
		TXT = TXT & PlanText & CRLF
	End If
	
	If Right(TXT, 2) <> CRLF Then _
		TXT = TXT & CRLF
	
	Return TXT
End Function
