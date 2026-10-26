#include "common.bi"
#include "string_support.bi"
#include "file.bi"

'====================================================================
Type HANDLES
	StdOut As Integer
	StdIn As Integer
	StdErr As Integer
End Type

Type PARAMS_
	UserName As String
	ShowInfoLabels As Boolean
End Type

'====================================================================
Declare Sub Main()
Declare Function OpenHandles(ByRef h As HANDLES) As Boolean
Declare Sub CloseHandles(ByRef h As HANDLES)
Declare Sub FillParams(ByRef h As HANDLES, ByRef Params As PARAMS_)
Declare Function GetFileContents(ByVal FileName As String) As String
Declare Function GetRequestLine(ByRef h As HANDLES) As String
Declare Function EscapeText(ByVal TXT As String, ByVal LeaveTabsAndNewLines As Boolean = False) As String
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
	
	' Открываем потоки...
	If Not OpenHandles(h) Then Exit Sub
	
	' Debug!
	'Print Environ("PATH")
	
	' Будем игнорировать любые ошибки тут...
	FillParams h, Params
	
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
	'Dim hFile As Integer
	'Open "invalid""file.dat" For Output As #hFile
	
	Return True
hError:
	' Вообще-то, оно всё автоматом закорется при выходе 
	' из программы, но на всякий случай...
	CloseHandles h
	Return False
End Function

'====================================================================
Public Sub CloseHandles(ByRef h As HANDLES)
	' Сюда мы попадаем при нормальном завершении программы и при 
	' ошибке инициализации программы в OpenHandles(), так что 
	' проверяем, открыт ли вообще хэндл. На всякий случай...
	MyClose h.StdOut
	MyClose h.StdIn
	MyClose h.StdErr
End Sub

'====================================================================
Private Sub FillParams(ByRef h As HANDLES, _
                       ByRef Params As PARAMS_)
	Dim TXT As String
	
	Const DEFAULT_USER = "anonymous"
	
	' Получаем имя пользователя из переменной окружения. После 
	' чего обрезаем его, в том числе от CR и LF. А потом ещё 
	' и ловеркейсим. Для красоты. Ну и для того, чтобы потом при 
	' сравнении имени пользователя с тем, что прилетело 
	' в запросе, не делать LCase() лишний раз...
	Params.UserName = Environ("FINGER_NAME")
	Params.UserName = MyTrim2(Params.UserName)
	Params.UserName = LCase(Params.UserName)
	
	' Проверяем, вдруг имя пользователя содержит пробелы или 
	' собачки...
	If InStr(Params.UserName, Any " @") > 0 Then
		Print #h.StdErr, "FINGER_NAME contains ""@"" or space. " & _
		                 "We will use default name."
		Params.UserName = DEFAULT_USER
	End If
	
	' Если в итоге ничего не осталось, то устанавливаем это 
	' дефолтное имя...
	If Params.UserName = "" Then _
		Params.UserName = DEFAULT_USER
	
	' По умолчанию - True. Если это не строго определённые 
	' значения, то - True. Так-то...
	TXT = Environ("FINGER_INFO_LABELS")
	TXT = MyTrim2(TXT)
	TXT = LCase(TXT)
	
	Select Case TXT
		Case "false", "0", "no"
			Params.ShowInfoLabels = False
		Case Else
			Params.ShowInfoLabels = True
	End Select
End Sub

'====================================================================
Private Function GetFileContents(ByVal FileName As String) As String
	Dim hFile As Integer
	Dim Text As String
	Dim TXT As String
	
	' Ограничем количество информации, которые читаем из файлов 
	' четырьмя байтами. Б – безопасность!
	Const MAX_BUFFER = 1024 * 4
	
	On Error GoTo hError
	
	' Сразу возвращаем пустоту...
	If FileName = "" Then Return ""
	
	' Пытаемся читать файл...
	hFile = FreeFile
	Open FileName For Input As #hFile
		'Text = Input(LOF(hFile), #hFile)
		Text = Input(MAX_BUFFER, #hFile)
	MyClose hFile
	
	' Возвращаем полученное!
	Return Text
	
hError:
	MyClose hFile
	Return ""
End Function

'====================================================================
Private Function GetRequestLine(ByRef h As HANDLES) As String
	Dim TXT As String
	Dim zTXT As ZString Ptr
	Dim TMP As Integer
	
	Const MAX_BUFFER = 100
	
	On Error GoTo hError
	
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
	' 
	' Line Input, с другой стороны, не безопасен, однако, во 
	' FreeBasic 1.10.0 появился второй вариант функции, который 
	' сделан через задницу, но работает как надо. Поэтому ниже 
	' используем именно его. Нет, передать String туда нельзя, 
	' только указатель на ZString.
	' 
	' Проверяем, выделилось ли хоть что-то!
	zTXT = CAllocate(MAX_BUFFER + 10, SizeOf(ZString))
	If zTXT = 0 Then Return ""
	
	' Я знаю, что ZString – это один байт, но раз выше мы 
	' учитываем актуальный размер, то и тут будем!
	Line Input #h.StdIn, *zTXT, MAX_BUFFER * SizeOf(ZString)
	If Err = 0 Then TXT = *zTXT
	
	' Обязательно освобождаем память!
	Deallocate zTXT
	
	' Оставляем только первую строку. По идее, Line Input сам 
	' читает до переноса строки, но мы подстрахуемся!
	TMP = InStr(TXT, CR)
	If TMP > 0 Then TXT = Left(TXT, TMP - 1)
	
	TMP = InStr(TXT, LF)
	If TMP > 0 Then TXT = Left(TXT, TMP - 1)
	
	' Возвращаем...
	Return TXT
	
hError:
	' Освобождаем память и возвращаем пустоту...
	Deallocate zTXT
	Return ""
End Function

'====================================================================
' Странное разделение строк на слэш и символ сделано для того, чтобы 
' при включении ворнингов компилятор на это не жаловался...
' 
' Отныне вместо разделения строк прямо указываем, что ескейпы 
' не нужны. Делается это баксом перед строкой. Если вдруг, 
' восклицательный перед строкой включает ескейпы.
' 
' Оказалось, что ESC тоже стоит ескейпить...
'====================================================================
Private Function EscapeText(ByVal TXT As String, _
                            ByVal LeaveTabsAndNewLines As Boolean = False) As String
	Dim TMP As Integer
	Dim TXT2 As String
	Dim Ch As String
	Dim nCh As Integer
	
	' Сделаем два цикла, чтобы на каждой итерации не вызывать 
	' If. Оптимизация!
	If LeaveTabsAndNewLines Then
		For TMP = 1 To Len(TXT)
			Ch = Mid(TXT, TMP, 1)
			nCh = Asc(Ch) ' Кэшируем, так сказать...
			
			' Попробуем экранировать все непечатаемые символы, 
			' в том числе те, для которых нет красивой буквы...
			If nCh < 32 Then
				Select Case Ch
					Case NUL:   Ch = $"\0"
					Case CR:    ' Не трогаем!
					Case LF:    ' Не трогаем!
					Case A_TAB: ' Не трогаем!
					Case V_TAB: ' Не трогаем!
					Case BS:    Ch = $"\b"
					Case FF:    Ch = $"\f"
					Case BEL:   Ch = $"\a"
					Case ESC:   Ch = $"\e"
					Case Else:  Ch = $"\x" & Hex(nCh, 2)
				End Select
			End If
			
			TXT2 = TXT2 & Ch
		Next TMP
	Else
		For TMP = 1 To Len(TXT)
			Ch = Mid(TXT, TMP, 1)
			nCh = Asc(Ch) ' Кэшируем, так сказать...
			
			' Попробуем экранировать все непечатаемые символы, 
			' в том числе те, для которых нет красивой буквы...
			If nCh < 32 Then
				Select Case Ch
					Case NUL:   Ch = $"\0"
					Case CR:    Ch = $"\r"
					Case LF:    Ch = $"\n"
					Case A_TAB: Ch = $"\t"
					Case V_TAB: Ch = $"\v"
					Case BS:    Ch = $"\b"
					Case FF:    Ch = $"\f"
					Case BEL:   Ch = $"\a"
					Case ESC:   Ch = $"\e"
					Case Else:  Ch = $"\x" & Hex(nCh, 2)
				End Select
			End If
			
			TXT2 = TXT2 & Ch
		Next TMP
	End If
	
	Return TXT2
End Function

'====================================================================
Private Function GetResponseBlock(ByVal Request As String, _
                                  ByRef Params As PARAMS_) As String
	Dim WideMode As Boolean = False
	Dim RC As Integer
	
	' Зачищаем запрос. Оставляем только одну строку!
	RC = InStr(Request, CR)
	If RC > 0 Then Request = Left(Request, RC - 1)
	RC = InStr(Request, LF)
	If RC > 0 Then Request = Left(Request, RC - 1)
	
	' Удаляем пробелы и табы, после чего добавляем пробел. Это 
	' нужно, чтобы легче было отлавливать «/w» ниже...
	Request = MyTrim(Request)
	Request = Request & " "
	
	' Debug!
	'Print """" & EscapeText(Request) & """"
	
	' Проверяем и выкидываем «/w»...
	If UCase(Left(Request, 3)) = "/W " Then
		WideMode = True
		Request = Mid(Request, 4)
	End If
	
	' Убираем пробелы, которые ранее могли добавиться или 
	' появиться. Убираем и слева, и справа. Дело в том, что 
	' у нас к строке добавлялся пробел справа, а ещё, при 
	' отрезании «/w» пробелы могли появиться слева (если оно 
	' было отделено более, чем одним пробелом)...
	Request = MyTrim(Request)
	
	' Debug!
	'Print """" & EscapeText(Request) & """"
	
	' Если в тексте есть пробелы, то нафиг...
	If InStr(Request, " ") > 0 Then _
		Return "Invalid Finger query" & CRLF
	
	' Если в тексте есть собака, то думаем, что там хост 
	' указан, даже если это не так. Лучше перестраховаться. 
	' Нейросеть говорит, что имя пользователя может содержать 
	' собачку, но я просто запрещаю такие имена пользователя, 
	' ибо можно запутаться, что имеется в виду...
	If InStr(Request, "@") > 0 Then _
		Return "Forwarding is not allowed" & CRLF
	
	' А теперь проверяем, что там прилетело. Имя пользователя 
	' в Params уже приведено к нижнему регистру при 
	' инициализации!
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
	
	' Читаем содержимое файлов. Содержимое переменных можно 
	' не проверять – в самой функции это будет проверено...
	ContactText = GetFileContents(Environ("FINGER_CONTACT"))
	ProjectText = GetFileContents(Environ("FINGER_PROJECT"))
	PlanText = GetFileContents(Environ("FINGER_PLAN"))
	
	' Приводим переносы строки к CRLF. как требует стандарт...
	ContactText = FixCRLF(ContactText)
	ProjectText = FixCRLF(ProjectText)
	PlanText = FixCRLF(PlanText)
	
	' Заескейпим всякое нечитаемое! По стандарту фильтровать 
	' неправильные символы должен клиент, но мы тоже это 
	' сделаем...
	' 
	' Кстати, табы тоже экранируются. Надо подумать...
	ContactText = EscapeText(ContactText, True)
	ProjectText = EscapeText(ProjectText, True)
	PlanText = EscapeText(PlanText, True)
	
	' Наращиваем строку ответа содержимым файлов 
	' с соответствующими метками, если они нужны...
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
	
	' Удаляем последний перенос!
	If Right(TXT, 2) <> CRLF Then _
		TXT = TXT & CRLF
	
	Return TXT
End Function
