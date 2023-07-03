#include "string_support.bi"
#include "chars.bi"

'====================================================================
' Приводит концы строк к виндовым. Ибо нефиг!
'====================================================================
Public Function FixCRLF(ByVal Text As String) As String
  Text = Replace(Text, CRLF, CR)
  Text = Replace(Text, LF, CR)
  Text = Replace(Text, CR, CRLF)
  
  FixCRLF = Text
End Function

'====================================================================
' Приводит концы строк к линуксовым.
'====================================================================
Public Function FixLF(ByVal Text As String) As String
  Text = Replace(Text, CRLF, LF)
  Text = Replace(Text, CR, LF)
  
  FixLF = Text
End Function

'====================================================================
' Приводит концы строк к маковым.
'====================================================================
Public Function FixCR(ByVal Text As String) As String
  Text = Replace(Text, CRLF, CR)
  Text = Replace(Text, LF, CR)
  
  FixCR = Text
End Function

'====================================================================
Public Function Replace(ByVal Expression As String, _
                        ByVal FindWhat As String, _
                        ByVal ReplaceWith As String, _
                        ByVal StartAt As Integer = 1, _
                        ByVal Count As Integer = -1, _
                        ByVal CaseSensitive As Boolean = True) As String
  Dim RC As Integer
  Dim lFindWhat As Integer
  Dim lReplaceWith As Integer
  Dim LastIndex As Integer
  
  ' Так в VB6!
  If Count = 0 Then
    Replace = Expression
    Exit Function
  End If
  
  ' StartAt в VB6 на самом деле не начинал замену с указанного 
  ' индекса, а обрезал строку! =_=
  ' Будем игнорировать значения меньше единицы, хотя в оригинале они 
  ' вызывали ошибку...
  If StartAt > 1 Then _
    Expression = Mid(Expression, StartAt)
  
  ' Кэшируем это, чтобы не вызывать по сто раз...
  lFindWhat = Len(FindWhat)
  lReplaceWith = Len(ReplaceWith)
  
  ' Debug!
  'Print Len(FindWhat)
  'Print Len(ReplaceWith)
  'Print lstrlen(ReplaceWith)
  
  ' Поиск начинаем с первого символа, разумеется...
  ' В прошлой версии алгоритма я пыталась использовать StartAt (но 
  ' забыла об этом на полпути). Теперь я использую отдельную 
  ' переменную, чтобы не плодить неоднозначности, ибо, как 
  ' выяснилось, StartAt выполняет совсем другую функцию, срезая 
  ' строку. Вот где-то на открытии среза я и позабыла использовать 
  ' StartAt в InStr(). Короче, другая переменная, и всё.
  LastIndex = 1
  
  Do
    If CaseSensitive Then
      RC = InStr(LastIndex, Expression, FindWhat)
    Else
      RC = InStr(LastIndex, UCase(Expression), UCase(FindWhat))
    End If
    If RC = 0 Then
      Replace = Expression
      Exit Function
    Else
      'Print RC
      'Print """" & Left(Expression, RC - 1) & """"
      'Print """" & Mid(Expression, RC + lFindWhat) & """"
      
      Expression = Left(Expression, RC - 1) & _
                   ReplaceWith & _
                   Mid(Expression, RC + lFindWhat)
      LastIndex = RC + lReplaceWith
      
      ' В оригинале, всё, что меньше -1 - ошибка. Но мы будем 
      ' считать, что всё, что меньше нуля - привильное значение. Так 
      ' нам легче считать.
      If Count > 0 Then
        Count = Count - 1
        If Count <= 0 Then
          Replace = Expression
          Exit Function
        End If
      End If
    End If
  Loop
End Function
