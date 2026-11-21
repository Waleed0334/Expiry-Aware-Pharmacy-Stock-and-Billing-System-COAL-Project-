; Expiry-Aware Pharmacy Stock and Billing System in x86 Assembly (MASM + Irvine32)
TITLE Expiry-Aware Pharmacy Stock and Billing System (x86 MASM + Irvine32)

INCLUDE Irvine32.inc

; Constants, macros and data: limits, repeated tasks and all arrays
MAX_MEDICINES    = 30
MAX_BATCHES      = 60
NAME_SIZE        = 20
MAX_BILL_ITEMS   = 10
MAX_ATTEMPTS     = 3
LOW_STOCK_LIMIT  = 10
TARGET_STOCK     = 30
SOON_DAYS        = 30
DISCOUNT_LIMIT   = 1000
DISCOUNT_PERCENT = 5
ROWS_PER_PAGE    = 15

STATUS_OK        = 0
STATUS_SOON      = 1
STATUS_EXPIRED   = 2

COUNTERS_SIZE    = 28

NEWLINE EQU <0Dh, 0Ah>

PrintText MACRO message
    push edx
    mov  edx, OFFSET message
    call WriteString
    pop  edx
ENDM

PrintColored MACRO color, message
    push eax
    mov  eax, color
    call SetTextColor
    PrintText message
    mov  eax, white
    call SetTextColor
    pop  eax
ENDM

MoveCursor MACRO row, col
    push edx
    mov  dh, row
    mov  dl, col
    call Gotoxy
    pop  edx
ENDM

WriteBlock MACRO dataLabel, byteCount
    mov  eax, fileHandle
    mov  edx, OFFSET dataLabel
    mov  ecx, byteCount
    call WriteToFile
ENDM

ReadBlock MACRO dataLabel, byteCount
    mov  eax, fileHandle
    mov  edx, OFFSET dataLabel
    mov  ecx, byteCount
    call ReadFromFile
ENDM

.data

correctPassword BYTE "pharma123", 0
typedPassword   BYTE 20 DUP(0)
dataFileName    BYTE "pharmacy_data.bin", 0
fileHandle      DWORD ?

; The first 7 DWORDs below must stay together (they are saved as one block)
medCount     DWORD 0
batCount     DWORD 0
billCount    DWORD 0
itemsSold    DWORD 0
totalSales   DWORD 0
maxBill      DWORD 0
lastSaleDate DWORD 0

todayDate    DWORD 0

medID    DWORD MAX_MEDICINES DUP(0)
medName  BYTE  (MAX_MEDICINES * NAME_SIZE) DUP(0)
medPrice DWORD MAX_MEDICINES DUP(0)
medSold  DWORD MAX_MEDICINES DUP(0)

batMed    DWORD MAX_BATCHES DUP(0)
batQty    DWORD MAX_BATCHES DUP(0)
batExpiry DWORD MAX_BATCHES DUP(0)

billItemCount  DWORD 0
billItemMed    DWORD MAX_BILL_ITEMS DUP(0)
billItemQty    DWORD MAX_BILL_ITEMS DUP(0)
billItemAmount DWORD MAX_BILL_ITEMS DUP(0)
billSubtotal   DWORD 0
billDiscount   DWORD 0
billTotal      DWORD 0

expiredLoss DWORD 0
soonLoss    DWORD 0
lossRows    DWORD 0
lowCount    DWORD 0
lowList     DWORD MAX_MEDICINES DUP(0)
searchName  BYTE  NAME_SIZE DUP(0)
tmpName     BYTE  NAME_SIZE DUP(0)
readBuf     BYTE  80 DUP(0)

; Days in each month (February allows 29)
monthDays   BYTE 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

msgWelcome      BYTE "=== EXPIRY-AWARE PHARMACY SYSTEM ===", NEWLINE, NEWLINE, 0
msgLoadedInfo   BYTE "Saved data loaded. Medicines: ", 0
msgBatchesInfo  BYTE "   Batches: ", 0
msgAskToday     BYTE NEWLINE, "Enter today's date (YYYYMMDD, e.g. 20261104): ", 0
msgAskPassword  BYTE "Enter password: ", 0
msgWrongPass    BYTE "Wrong password!", NEWLINE, 0
msgTooMany      BYTE "Too many wrong attempts. Program closing.", NEWLINE, 0
msgLoginOk      BYTE "Login successful!", NEWLINE, 0

msgBadNumber    BYTE "Please enter a valid number: ", 0
msgMustBePos    BYTE "Value must be greater than zero. Try again: ", 0
msgBadDate      BYTE "Invalid date! Use a real date as YYYYMMDD (year 2000-2100). Try again: ", 0
msgBadChoice    BYTE "Invalid choice!", NEWLINE, 0
msgNameEmpty    BYTE "Name cannot be empty. Try again: ", 0
msgMedNotFound  BYTE "Medicine not found!", NEWLINE, 0

menuTitleTop    BYTE "==========================================", NEWLINE, 0
menuTitle       BYTE "      EXPIRY-AWARE PHARMACY SYSTEM", NEWLINE, 0
msgTodayIs      BYTE "      Today's date: ", 0
menuItem1       BYTE "   1.  Add Medicine", NEWLINE, 0
menuItem2       BYTE "   2.  Add Batch / Restock", NEWLINE, 0
menuItem3       BYTE "   3.  View Stock", NEWLINE, 0
menuItem4       BYTE "   4.  Search Medicine", NEWLINE, 0
menuItem5       BYTE "   5.  Update / Delete Medicine", NEWLINE, 0
menuItem6       BYTE "   6.  Sort Medicines", NEWLINE, 0
menuItem7       BYTE "   7.  Sell Medicine and Print Bill", NEWLINE, 0
menuItem8       BYTE "   8.  Expiry Loss Report", NEWLINE, 0
menuItem9       BYTE "   9.  Reorder Suggestion", NEWLINE, 0
menuItem10      BYTE "   10. Daily Sales Report", NEWLINE, 0
menuItem0       BYTE "   0.  Save and Exit", NEWLINE, 0
menuLine        BYTE "------------------------------------------", NEWLINE, 0
msgEnterChoice  BYTE "   Enter your choice: ", 0

msgMedFull      BYTE "Medicine list is full (max 30)!", NEWLINE, 0
msgBatchFull    BYTE "Batch list is full (max 60)!", NEWLINE, 0
msgAskId        BYTE "Enter medicine ID: ", 0
msgDuplicateId  BYTE "This ID already exists!", NEWLINE, 0
msgAskName      BYTE "Enter medicine name (max 19 letters): ", 0
msgAskPrice     BYTE "Enter price per unit (Rs.): ", 0
msgMedAdded     BYTE "Medicine added successfully!", NEWLINE, 0
msgAskQty       BYTE "Enter batch quantity: ", 0
msgAskExpiry    BYTE "Enter expiry date (YYYYMMDD): ", 0
msgBatchAdded   BYTE "Batch added successfully!", NEWLINE, 0

msgStockHeader  BYTE NEWLINE, "------------- CURRENT STOCK -------------", NEWLINE, 0
msgNoMeds       BYTE "No medicines in the system yet.", NEWLINE, 0
msgLabelId      BYTE "ID: ", 0
msgLabelName    BYTE "   Name: ", 0
msgLabelPrice   BYTE "   Price: Rs. ", 0
msgLabelStock   BYTE "   Usable stock: ", 0
msgBatchQty     BYTE "     Batch -> Qty: ", 0
msgBatchExpiry  BYTE "   Expiry: ", 0
msgTagOk        BYTE "  [OK]", 0
msgTagSoon      BYTE "  [EXPIRES SOON]", 0
msgTagExpired   BYTE "  [EXPIRED]", 0
msgSearchMenu   BYTE "Search by:  1 = ID    2 = Name   : ", 0

msgUpdateMenu   BYTE "1 = Update price    2 = Delete medicine : ", 0
msgAskNewPrice  BYTE "Enter new price (Rs.): ", 0
msgPriceUpdated BYTE "Price updated!", NEWLINE, 0
msgConfirmDel   BYTE "Delete medicine and ALL its batches? (y/n): ", 0
msgMedDeleted   BYTE "Medicine deleted.", NEWLINE, 0
msgCancelled    BYTE "Cancelled.", NEWLINE, 0

msgNeedTwoMeds  BYTE "Need at least 2 medicines to sort.", NEWLINE, 0
msgSortMenu     BYTE "Sort by:  1 = Name (A to Z)    2 = Price (low to high) : ", 0
msgSorted       BYTE "Medicines sorted!", NEWLINE, 0

msgSellHeader   BYTE NEWLINE, "------------- SELL MEDICINE -------------", NEWLINE, 0
msgSellAskId    BYTE "Enter medicine ID to sell (0 = finish bill): ", 0
msgShowStock    BYTE "Usable (non-expired) stock: ", 0
msgOutOfStock   BYTE "No usable stock for this medicine!", NEWLINE, 0
msgSellAskQty   BYTE "Enter quantity to sell: ", 0
msgNotEnough    BYTE "Not enough stock! Sale refused.", NEWLINE, 0
msgItemAdded    BYTE "Item added to bill.", NEWLINE, 0
msgBillFull     BYTE "Bill is full (max 10 items). Finishing bill.", NEWLINE, 0
msgNoItemsSold  BYTE "No items were sold.", NEWLINE, 0

msgReceiptTop   BYTE "=============== PHARMACY BILL ===============", NEWLINE, 0
msgBillNo       BYTE "Bill No: ", 0
msgBillDate     BYTE "     Date: ", 0
msgTimes        BYTE "  x ", 0
msgEquals       BYTE "  =  Rs. ", 0
msgSubtotal     BYTE "Subtotal      : Rs. ", 0
msgDiscount     BYTE "Discount (5%) : Rs. ", 0
msgTotal        BYTE "TOTAL         : Rs. ", 0
msgReceiptEnd   BYTE "==============================================", NEWLINE, 0

msgLossHeader   BYTE NEWLINE, "---------- EXPIRY LOSS REPORT ----------", NEWLINE, 0
msgQtyLabel     BYTE "   Qty: ", 0
msgExpiryLabel  BYTE "   Expiry: ", 0
msgValueLabel   BYTE "   Value: Rs. ", 0
msgNoRisk       BYTE "No expired or soon-to-expire stock. Great!", NEWLINE, 0
msgExpiredTotal BYTE "Total EXPIRED stock value      : Rs. ", 0
msgSoonTotal    BYTE "Total SOON-TO-EXPIRE value     : Rs. ", 0
msgRiskTotal    BYTE "TOTAL MONEY AT RISK            : Rs. ", 0

msgReorderHead  BYTE NEWLINE, "---------- REORDER SUGGESTION (fast sellers first) ----------", NEWLINE, 0
msgAllGood      BYTE "All medicines have enough usable stock.", NEWLINE, 0
msgUsableLabel  BYTE "   Usable stock: ", 0
msgSoldLabel    BYTE "   Sold so far: ", 0
msgOrderLabel   BYTE "   -> ORDER: ", 0

msgSalesHeader  BYTE NEWLINE, "------------ DAILY SALES REPORT ------------", NEWLINE, 0
msgSalesDate    BYTE "Date              : ", 0
msgSalesBills   BYTE "Number of bills   : ", 0
msgSalesItems   BYTE "Items (units) sold: ", 0
msgSalesTotal   BYTE "Total sales       : Rs. ", 0
msgSalesMax     BYTE "Highest bill      : Rs. ", 0

msgSaved        BYTE "Data saved to file.", NEWLINE, 0
msgSaveError    BYTE "ERROR: could not create the data file!", NEWLINE, 0
msgGoodbye      BYTE "Goodbye!", NEWLINE, 0

.code

; Main program flow: load file, ask date, login, menu loop, save and exit
main PROC
    call LoadDataFromFile
    call AskTodayDate
    call StaffLogin
    cmp  eax, 1
    je   LoginSuccess
    PrintColored lightRed, msgTooMany
    call WaitMsg
    exit

LoginSuccess:
    PrintColored lightGreen, msgLoginOk
    call WaitMsg

MenuLoop:
    call ShowMainMenu
    call ReadNumber

    cmp  eax, 0
    je   SaveAndExit
    cmp  eax, 1
    je   Choice1
    cmp  eax, 2
    je   Choice2
    cmp  eax, 3
    je   Choice3
    cmp  eax, 4
    je   Choice4
    cmp  eax, 5
    je   Choice5
    cmp  eax, 6
    je   Choice6
    cmp  eax, 7
    je   Choice7
    cmp  eax, 8
    je   Choice8
    cmp  eax, 9
    je   Choice9
    cmp  eax, 10
    je   Choice10
    PrintColored lightRed, msgBadChoice
    jmp  BackToMenu

; Choices that change data call AutoSave so nothing is lost if the window closes
Choice1:  call AddMedicine
          call AutoSave
          jmp  BackToMenu
Choice2:  call AddBatch
          call AutoSave
          jmp  BackToMenu
Choice3:  call ViewStock
          jmp  BackToMenu
Choice4:  call SearchMedicine
          jmp  BackToMenu
Choice5:  call UpdateDeleteMedicine
          call AutoSave
          jmp  BackToMenu
Choice6:  call SortMedicines
          call AutoSave
          jmp  BackToMenu
Choice7:  call SellMedicine
          call AutoSave
          jmp  BackToMenu
Choice8:  call ExpiryLossReport
          jmp  BackToMenu
Choice9:  call ReorderSuggestion
          jmp  BackToMenu
Choice10: call DailySalesReport

BackToMenu:
    call Crlf
    call WaitMsg
    jmp  MenuLoop

SaveAndExit:
    call SaveDataToFile
    PrintColored lightCyan, msgGoodbye
    call WaitMsg
    exit
main ENDP

; Input validation: rejects invalid, zero, negative numbers and bad dates
ReadNumber PROC
TryAgain:
    call ReadInt
    jno  GotNumber
    PrintColored lightRed, msgBadNumber
    jmp  TryAgain
GotNumber:
    ret
ReadNumber ENDP

ReadPositive PROC
AskAgain:
    call ReadNumber
    test eax, eax
    jg   NumberIsGood
    PrintColored lightRed, msgMustBePos
    jmp  AskAgain
NumberIsGood:
    ret
ReadPositive ENDP

; Reads a line safely. In: EDX = destination, ECX = max characters.
; Reads into a large buffer first so extra typed characters never stay
; behind and spoil the next input, then copies at most ECX characters.
ReadLimited PROC USES ebx edx esi
    mov  ebx, edx
    push ecx
    mov  edx, OFFSET readBuf
    mov  ecx, 79
    call ReadString
    pop  ecx
    cmp  eax, ecx
    jbe  LengthOk
    mov  BYTE PTR readBuf[ecx], 0
    mov  eax, ecx
LengthOk:
    mov  esi, eax
    INVOKE Str_copy, ADDR readBuf, ebx
    mov  eax, esi
    ret
ReadLimited ENDP

ReadNonEmptyName PROC USES ecx
AskName:
    mov  ecx, NAME_SIZE - 1
    call ReadLimited
    INVOKE Str_length, edx
    test eax, eax
    jnz  GotName
    PrintColored lightRed, msgNameEmpty
    jmp  AskName
GotName:
    ret
ReadNonEmptyName ENDP

; Checks YYYYMMDD. Input EAX = date, output EBX = 1 (valid) or 0 (invalid)
IsValidDate PROC USES eax ecx edx
    mov  ebx, 0
    cmp  eax, 20000101
    jl   DateIsBad
    cmp  eax, 21001231
    jg   DateIsBad

    mov  edx, 0
    mov  ecx, 10000
    div  ecx
    mov  eax, edx
    mov  edx, 0
    mov  ecx, 100
    div  ecx

    cmp  eax, 1
    jl   DateIsBad
    cmp  eax, 12
    jg   DateIsBad
    cmp  edx, 1
    jl   DateIsBad
    movzx ecx, BYTE PTR monthDays[eax - 1]
    cmp  edx, ecx
    jg   DateIsBad
    mov  ebx, 1
DateIsBad:
    ret
IsValidDate ENDP

ReadValidDate PROC USES ebx
AskDateAgain:
    call ReadNumber
    call IsValidDate
    cmp  ebx, 1
    je   DateAccepted
    PrintColored lightRed, msgBadDate
    jmp  AskDateAgain
DateAccepted:
    ret
ReadValidDate ENDP

; Expiry logic: classifies each batch as OK, expiring soon or expired
DateToDays PROC USES ebx ecx edx
    mov  edx, 0
    mov  ebx, 10000
    div  ebx
    imul eax, 372
    mov  ecx, eax
    mov  eax, edx
    mov  edx, 0
    mov  ebx, 100
    div  ebx
    imul eax, 31
    add  eax, edx
    add  eax, ecx
    ret
DateToDays ENDP

GetBatchStatus PROC USES ebx
    cmp  eax, todayDate
    jl   BatchIsExpired

    call DateToDays
    mov  ebx, eax
    mov  eax, todayDate
    call DateToDays
    sub  ebx, eax
    cmp  ebx, SOON_DAYS
    jle  BatchIsSoon
    mov  eax, STATUS_OK
    ret
BatchIsSoon:
    mov  eax, STATUS_SOON
    ret
BatchIsExpired:
    mov  eax, STATUS_EXPIRED
    ret
GetBatchStatus ENDP

; Array helpers: find medicines, usable stock, remove batches and medicines
GetNameAddress PROC USES eax
    imul eax, NAME_SIZE
    mov  edx, OFFSET medName
    add  edx, eax
    ret
GetNameAddress ENDP

PrintMedName PROC USES edx
    call GetNameAddress
    call WriteString
    ret
PrintMedName ENDP

FindMedicineById PROC USES ecx esi
    mov  esi, 0
    mov  ecx, medCount
    cmp  ecx, 0
    je   IdNotFound
SearchLoop:
    cmp  medID[esi*4], eax
    je   IdFound
    inc  esi
    loop SearchLoop
IdNotFound:
    mov  eax, -1
    ret
IdFound:
    mov  eax, esi
    ret
FindMedicineById ENDP

; Case-insensitive name search. In: EDX = name to find. Out: EAX = index or -1
FindMedicineByName PROC USES ecx edx esi edi
    mov  edi, edx
    INVOKE Str_ucase, edi
    mov  esi, 0
    mov  ecx, medCount
    cmp  ecx, 0
    je   NameNotFound
NameLoop:
    mov  eax, esi
    call GetNameAddress
    INVOKE Str_copy, edx, ADDR tmpName
    INVOKE Str_ucase, ADDR tmpName
    INVOKE Str_compare, ADDR tmpName, edi
    je   NameFound
    inc  esi
    loop NameLoop
NameNotFound:
    mov  eax, -1
    ret
NameFound:
    mov  eax, esi
    ret
FindMedicineByName ENDP

GetUsableStock PROC USES ebx ecx esi edi
    mov  edi, eax
    mov  ebx, 0
    mov  esi, 0
    mov  ecx, batCount
    cmp  ecx, 0
    je   StockDone
BatchLoop:
    cmp  batMed[esi*4], edi
    jne  NextBatch
    mov  eax, batExpiry[esi*4]
    call GetBatchStatus
    cmp  eax, STATUS_EXPIRED
    je   NextBatch
    add  ebx, batQty[esi*4]
NextBatch:
    inc  esi
    loop BatchLoop
StockDone:
    mov  eax, ebx
    ret
GetUsableStock ENDP

RemoveBatchAt PROC USES eax ebx ecx esi
    mov  esi, eax
ShiftBatchLoop:
    mov  ebx, esi
    inc  ebx
    cmp  ebx, batCount
    jge  ShiftBatchDone
    mov  ecx, batMed[ebx*4]
    mov  batMed[esi*4], ecx
    mov  ecx, batQty[ebx*4]
    mov  batQty[esi*4], ecx
    mov  ecx, batExpiry[ebx*4]
    mov  batExpiry[esi*4], ecx
    inc  esi
    jmp  ShiftBatchLoop
ShiftBatchDone:
    dec  batCount
    ret
RemoveBatchAt ENDP

CleanEmptyBatches PROC USES eax esi
    mov  esi, 0
CheckLoop:
    cmp  esi, batCount
    jge  CleanDone
    cmp  batQty[esi*4], 0
    jne  KeepThisBatch
    mov  eax, esi
    call RemoveBatchAt
    jmp  CheckLoop
KeepThisBatch:
    inc  esi
    jmp  CheckLoop
CleanDone:
    ret
CleanEmptyBatches ENDP

RemoveMedicineAt PROC USES eax ebx ecx edx esi edi
    mov  esi, eax
ShiftMedLoop:
    mov  ebx, esi
    inc  ebx
    cmp  ebx, medCount
    jge  ShiftMedDone
    mov  ecx, medID[ebx*4]
    mov  medID[esi*4], ecx
    mov  ecx, medPrice[ebx*4]
    mov  medPrice[esi*4], ecx
    mov  ecx, medSold[ebx*4]
    mov  medSold[esi*4], ecx
    mov  eax, ebx
    call GetNameAddress
    mov  edi, edx
    mov  eax, esi
    call GetNameAddress
    INVOKE Str_copy, edi, edx
    inc  esi
    jmp  ShiftMedLoop
ShiftMedDone:
    dec  medCount
    ret
RemoveMedicineAt ENDP

DeleteMedicine PROC USES eax esi edi
    mov  edi, eax

    mov  esi, 0
DelBatchLoop:
    cmp  esi, batCount
    jge  DelBatchesDone
    cmp  batMed[esi*4], edi
    jne  KeepBatch
    mov  eax, esi
    call RemoveBatchAt
    jmp  DelBatchLoop
KeepBatch:
    inc  esi
    jmp  DelBatchLoop

DelBatchesDone:
    mov  eax, edi
    call RemoveMedicineAt

    mov  esi, 0
FixIndexLoop:
    cmp  esi, batCount
    jge  FixIndexDone
    cmp  batMed[esi*4], edi
    jle  SkipFix
    dec  batMed[esi*4]
SkipFix:
    inc  esi
    jmp  FixIndexLoop
FixIndexDone:
    ret
DeleteMedicine ENDP

; Staff login: today's date entry and password check with 3 attempts
AskTodayDate PROC USES eax
    call Clrscr
    PrintColored lightCyan, msgWelcome
    PrintText msgLoadedInfo
    mov  eax, medCount
    call WriteDec
    PrintText msgBatchesInfo
    mov  eax, batCount
    call WriteDec
    call Crlf

    PrintText msgAskToday
    call ReadValidDate
    mov  todayDate, eax

    cmp  eax, lastSaleDate
    je   SameDay
    mov  billCount, 0
    mov  itemsSold, 0
    mov  totalSales, 0
    mov  maxBill, 0
    mov  lastSaleDate, eax
SameDay:
    ret
AskTodayDate ENDP

StaffLogin PROC USES ecx edx
    mov  ecx, MAX_ATTEMPTS
AskPassword:
    PrintText msgAskPassword
    mov  edx, OFFSET typedPassword
    push ecx
    mov  ecx, 19
    call ReadLimited
    pop  ecx
    INVOKE Str_compare, ADDR typedPassword, ADDR correctPassword
    je   PasswordOk
    PrintColored lightRed, msgWrongPass
    loop AskPassword
    mov  eax, 0
    ret
PasswordOk:
    mov  eax, 1
    ret
StaffLogin ENDP

; Colourful main menu using Gotoxy and SetTextColor
ShowMainMenu PROC USES eax edx
    call Clrscr
    MoveCursor 1, 0
    PrintColored lightCyan, menuTitleTop
    PrintColored lightCyan, menuTitle
    PrintColored lightCyan, menuTitleTop
    PrintText msgTodayIs
    mov  eax, todayDate
    call WriteDec
    call Crlf
    call Crlf
    PrintText menuItem1
    PrintText menuItem2
    PrintText menuItem3
    PrintText menuItem4
    PrintText menuItem5
    PrintText menuItem6
    PrintText menuItem7
    PrintColored lightRed, menuItem8
    PrintColored yellow, menuItem9
    PrintText menuItem10
    PrintColored lightGreen, menuItem0
    PrintColored gray, menuLine
    MoveCursor 18, 0
    PrintColored lightGreen, msgEnterChoice
    ret
ShowMainMenu ENDP

; Add Medicine and Add Batch: stores ID, name, price, quantity and expiry
AddMedicine PROC USES eax ebx ecx edx esi
    cmp  medCount, MAX_MEDICINES
    jl   HasRoom
    PrintColored lightRed, msgMedFull
    ret
HasRoom:
    PrintText msgAskId
    call ReadPositive
    mov  ebx, eax
    call FindMedicineById
    cmp  eax, -1
    je   IdIsNew
    PrintColored lightRed, msgDuplicateId
    ret
IdIsNew:
    mov  esi, medCount
    mov  medID[esi*4], ebx

    PrintText msgAskName
    mov  eax, esi
    call GetNameAddress
    call ReadNonEmptyName

    PrintText msgAskPrice
    call ReadPositive
    mov  medPrice[esi*4], eax
    mov  medSold[esi*4], 0
    inc  medCount
    PrintColored lightGreen, msgMedAdded
    ret
AddMedicine ENDP

AddBatch PROC USES eax ebx ecx edx
    cmp  batCount, MAX_BATCHES
    jl   BatchHasRoom
    PrintColored lightRed, msgBatchFull
    ret
BatchHasRoom:
    PrintText msgAskId
    call ReadPositive
    call FindMedicineById
    cmp  eax, -1
    jne  MedicineExists
    PrintColored lightRed, msgMedNotFound
    ret
MedicineExists:
    mov  ebx, eax
    PrintText msgAskQty
    call ReadPositive
    mov  ecx, eax
    PrintText msgAskExpiry
    call ReadValidDate

    mov  edx, batCount
    mov  batMed[edx*4], ebx
    mov  batQty[edx*4], ecx
    mov  batExpiry[edx*4], eax
    inc  batCount
    PrintColored lightGreen, msgBatchAdded
    ret
AddBatch ENDP

; View Stock and Search: expired batches in red, soon-to-expire in yellow
ShowMedicineDetails PROC USES eax ebx ecx edx esi edi
    mov  esi, eax

    PrintText msgLabelId
    mov  eax, medID[esi*4]
    call WriteDec
    PrintText msgLabelName
    mov  eax, esi
    call PrintMedName
    PrintText msgLabelPrice
    mov  eax, medPrice[esi*4]
    call WriteDec
    PrintText msgLabelStock
    mov  eax, esi
    call GetUsableStock
    call WriteDec
    call Crlf

    mov  edi, 0
BatchShowLoop:
    cmp  edi, batCount
    jge  ShowDone
    cmp  batMed[edi*4], esi
    jne  NextBatchShow

    mov  eax, batExpiry[edi*4]
    call GetBatchStatus
    mov  ebx, eax

    mov  eax, white
    cmp  ebx, STATUS_EXPIRED
    jne  NotExpiredColor
    mov  eax, lightRed
    jmp  ApplyColor
NotExpiredColor:
    cmp  ebx, STATUS_SOON
    jne  ApplyColor
    mov  eax, yellow
ApplyColor:
    call SetTextColor

    PrintText msgBatchQty
    mov  eax, batQty[edi*4]
    call WriteDec
    PrintText msgBatchExpiry
    mov  eax, batExpiry[edi*4]
    call WriteDec

    cmp  ebx, STATUS_EXPIRED
    je   TagExpired
    cmp  ebx, STATUS_SOON
    je   TagSoon
    PrintText msgTagOk
    jmp  TagDone
TagExpired:
    PrintText msgTagExpired
    jmp  TagDone
TagSoon:
    PrintText msgTagSoon
TagDone:
    call Crlf
    mov  eax, white
    call SetTextColor
NextBatchShow:
    inc  edi
    jmp  BatchShowLoop
ShowDone:
    ret
ShowMedicineDetails ENDP

; Shows all medicines and pauses after every 4 so the list does not scroll away
ViewStock PROC USES eax esi
    PrintColored lightCyan, msgStockHeader
    cmp  medCount, 0
    jne  HasMedicines
    PrintColored yellow, msgNoMeds
    ret
HasMedicines:
    mov  esi, 0
ViewLoop:
    mov  eax, esi
    call ShowMedicineDetails
    call Crlf
    inc  esi
    cmp  esi, medCount
    jge  ViewDone
    test esi, 3
    jnz  ViewLoop
    call WaitMsg
    jmp  ViewLoop
ViewDone:
    ret
ViewStock ENDP

SearchMedicine PROC USES eax edx
    PrintText msgSearchMenu
    call ReadNumber
    cmp  eax, 1
    je   SearchById
    cmp  eax, 2
    je   SearchByName
    PrintColored lightRed, msgBadChoice
    ret
SearchById:
    PrintText msgAskId
    call ReadPositive
    call FindMedicineById
    jmp  ShowSearchResult
SearchByName:
    PrintText msgAskName
    mov  edx, OFFSET searchName
    call ReadNonEmptyName
    mov  edx, OFFSET searchName
    call FindMedicineByName
ShowSearchResult:
    cmp  eax, -1
    jne  SearchFound
    PrintColored lightRed, msgMedNotFound
    ret
SearchFound:
    call Crlf
    call ShowMedicineDetails
    ret
SearchMedicine ENDP

; Update price or delete a medicine together with its batches
UpdateDeleteMedicine PROC USES eax ebx
    PrintText msgAskId
    call ReadPositive
    call FindMedicineById
    cmp  eax, -1
    jne  MedicineIsThere
    PrintColored lightRed, msgMedNotFound
    ret
MedicineIsThere:
    mov  ebx, eax
    PrintText msgUpdateMenu
    call ReadNumber
    cmp  eax, 1
    je   DoUpdatePrice
    cmp  eax, 2
    je   DoDelete
    PrintColored lightRed, msgBadChoice
    ret
DoUpdatePrice:
    PrintText msgAskNewPrice
    call ReadPositive
    mov  medPrice[ebx*4], eax
    PrintColored lightGreen, msgPriceUpdated
    ret
DoDelete:
    PrintText msgConfirmDel
    call ReadChar
    movzx eax, al
    call WriteChar
    call Crlf
    cmp  eax, 'y'
    je   ConfirmedDelete
    cmp  eax, 'Y'
    je   ConfirmedDelete
    PrintText msgCancelled
    ret
ConfirmedDelete:
    mov  eax, ebx
    call DeleteMedicine
    PrintColored lightGreen, msgMedDeleted
    ret
UpdateDeleteMedicine ENDP

; Sort Medicines: bubble sort by name (A to Z) or by price
CompareMedNames PROC USES eax edx
    mov  eax, esi
    call GetNameAddress
    push edx
    mov  eax, edi
    call GetNameAddress
    pop  eax
    INVOKE Str_compare, eax, edx
    ret
CompareMedNames ENDP

SwapMedicines PROC USES eax ebx ecx edx
    mov  eax, medID[esi*4]
    xchg eax, medID[edi*4]
    mov  medID[esi*4], eax

    mov  eax, medPrice[esi*4]
    xchg eax, medPrice[edi*4]
    mov  medPrice[esi*4], eax

    mov  eax, medSold[esi*4]
    xchg eax, medSold[edi*4]
    mov  medSold[esi*4], eax

    mov  eax, esi
    call GetNameAddress
    mov  ebx, edx
    mov  eax, edi
    call GetNameAddress
    mov  ecx, NAME_SIZE
SwapNameBytes:
    mov  al, [ebx]
    xchg al, [edx]
    mov  [ebx], al
    inc  ebx
    inc  edx
    loop SwapNameBytes

    mov  ebx, 0
FixBatchLoop:
    cmp  ebx, batCount
    jge  SwapDone
    mov  eax, batMed[ebx*4]
    cmp  eax, esi
    je   PointToEdi
    cmp  eax, edi
    je   PointToEsi
    jmp  NextFix
PointToEdi:
    mov  batMed[ebx*4], edi
    jmp  NextFix
PointToEsi:
    mov  batMed[ebx*4], esi
NextFix:
    inc  ebx
    jmp  FixBatchLoop
SwapDone:
    ret
SwapMedicines ENDP

SortMedicines PROC USES eax ebx ecx edx esi edi
    cmp  medCount, 2
    jge  EnoughToSort
    PrintColored yellow, msgNeedTwoMeds
    ret
EnoughToSort:
    PrintText msgSortMenu
    call ReadNumber
    mov  ebx, eax
    cmp  ebx, 1
    je   SortChosen
    cmp  ebx, 2
    je   SortChosen
    PrintColored lightRed, msgBadChoice
    ret
SortChosen:
    mov  ecx, medCount
    dec  ecx
OuterLoop:
    push ecx
    mov  esi, 0
InnerLoop:
    mov  edi, esi
    inc  edi
    cmp  edi, medCount
    jge  InnerDone

    cmp  ebx, 1
    je   CompareByName
    mov  eax, medPrice[esi*4]
    cmp  eax, medPrice[edi*4]
    jle  NoSwap
    jmp  DoSwap
CompareByName:
    call CompareMedNames
    jbe  NoSwap
DoSwap:
    call SwapMedicines
NoSwap:
    inc  esi
    jmp  InnerLoop
InnerDone:
    pop  ecx
    dec  ecx
    jnz  OuterLoop
    PrintColored lightGreen, msgSorted
    ret
SortMedicines ENDP

; Sell medicine: stock is taken from the earliest-expiry batch first
FindEarliestBatch PROC USES ecx edx esi edi
    mov  edi, -1
    mov  edx, 99999999
    mov  esi, 0
    mov  ecx, batCount
    cmp  ecx, 0
    je   EarliestDone
EarliestLoop:
    cmp  batMed[esi*4], ebx
    jne  EarliestNext
    cmp  batQty[esi*4], 0
    je   EarliestNext
    mov  eax, batExpiry[esi*4]
    cmp  eax, todayDate
    jl   EarliestNext
    cmp  eax, edx
    jge  EarliestNext
    mov  edx, eax
    mov  edi, esi
EarliestNext:
    inc  esi
    loop EarliestLoop
EarliestDone:
    mov  eax, edi
    ret
FindEarliestBatch ENDP

TakeStockFromBatches PROC USES eax ecx edx edi
    mov  edi, esi
TakeLoop:
    cmp  edi, 0
    je   TakeDone
    call FindEarliestBatch
    cmp  eax, -1
    je   TakeDone
    mov  ecx, batQty[eax*4]
    cmp  ecx, edi
    jle  TakeWholeBatch
    sub  batQty[eax*4], edi
    mov  edi, 0
    jmp  TakeDone
TakeWholeBatch:
    sub  edi, ecx
    mov  batQty[eax*4], 0
    jmp  TakeLoop
TakeDone:
    call CleanEmptyBatches
    ret
TakeStockFromBatches ENDP

; Billing: 5% discount at Rs. 1000 or more, receipt printing
CalculateBill PROC USES eax ebx edx
    mov  billDiscount, 0
    mov  eax, billSubtotal
    cmp  eax, DISCOUNT_LIMIT
    jl   NoDiscount
    mov  ebx, DISCOUNT_PERCENT
    mul  ebx
    mov  ebx, 100
    div  ebx
    mov  billDiscount, eax
NoDiscount:
    mov  eax, billSubtotal
    sub  eax, billDiscount
    mov  billTotal, eax
    ret
CalculateBill ENDP

PrintReceipt PROC USES eax esi
    call Crlf
    PrintColored lightCyan, msgReceiptTop
    PrintText msgBillNo
    mov  eax, billCount
    inc  eax
    call WriteDec
    PrintText msgBillDate
    mov  eax, todayDate
    call WriteDec
    call Crlf
    call Crlf

    mov  esi, 0
ReceiptLoop:
    cmp  esi, billItemCount
    jge  ReceiptItemsDone
    mov  eax, billItemMed[esi*4]
    call PrintMedName
    PrintText msgTimes
    mov  eax, billItemQty[esi*4]
    call WriteDec
    PrintText msgEquals
    mov  eax, billItemAmount[esi*4]
    call WriteDec
    call Crlf
    inc  esi
    jmp  ReceiptLoop

ReceiptItemsDone:
    call Crlf
    PrintText msgSubtotal
    mov  eax, billSubtotal
    call WriteDec
    call Crlf
    PrintText msgDiscount
    mov  eax, billDiscount
    call WriteDec
    call Crlf
    PrintColored lightGreen, msgTotal
    mov  eax, billTotal
    call WriteDec
    call Crlf
    PrintColored lightCyan, msgReceiptEnd
    ret
PrintReceipt ENDP

SellMedicine PROC USES eax ebx ecx edx esi edi
    mov  billItemCount, 0
    mov  billSubtotal, 0
    PrintColored lightCyan, msgSellHeader

AskItem:
    cmp  billItemCount, MAX_BILL_ITEMS
    jl   CanAddItem
    PrintColored yellow, msgBillFull
    jmp  FinishBill
CanAddItem:
    PrintText msgSellAskId
    call ReadNumber
    cmp  eax, 0
    je   FinishBill
    jg   IdIsPositive
    PrintColored lightRed, msgMustBePos
    jmp  AskItem
IdIsPositive:
    call FindMedicineById
    cmp  eax, -1
    jne  MedicineFound
    PrintColored lightRed, msgMedNotFound
    jmp  AskItem

MedicineFound:
    mov  ebx, eax
    call GetUsableStock
    mov  ecx, eax
    PrintText msgShowStock
    mov  eax, ecx
    call WriteDec
    call Crlf
    cmp  ecx, 0
    jne  AskQuantity
    PrintColored lightRed, msgOutOfStock
    jmp  AskItem

AskQuantity:
    PrintText msgSellAskQty
    call ReadPositive
    cmp  eax, ecx
    jle  StockIsEnough
    PrintColored lightRed, msgNotEnough
    jmp  AskItem

StockIsEnough:
    mov  esi, eax
    call TakeStockFromBatches

    mov  eax, esi
    imul eax, medPrice[ebx*4]
    add  billSubtotal, eax

    mov  edi, billItemCount
    mov  billItemMed[edi*4], ebx
    mov  billItemQty[edi*4], esi
    mov  billItemAmount[edi*4], eax
    inc  billItemCount

    add  medSold[ebx*4], esi
    add  itemsSold, esi
    PrintColored lightGreen, msgItemAdded
    jmp  AskItem

FinishBill:
    cmp  billItemCount, 0
    jne  HasItems
    PrintColored yellow, msgNoItemsSold
    ret
HasItems:
    call CalculateBill
    call PrintReceipt

    inc  billCount
    mov  eax, billTotal
    add  totalSales, eax
    cmp  eax, maxBill
    jle  KeepOldMax
    mov  maxBill, eax
KeepOldMax:
    ret
SellMedicine ENDP

; Expiry Loss Report: rupee value of expired and soon-to-expire stock
ExpiryLossReport PROC USES eax ebx ecx edx esi edi
    mov  expiredLoss, 0
    mov  soonLoss, 0
    mov  lossRows, 0
    PrintColored lightCyan, msgLossHeader

    mov  esi, 0
LossLoop:
    cmp  esi, batCount
    jge  LossLoopDone

    mov  eax, batExpiry[esi*4]
    call GetBatchStatus
    cmp  eax, STATUS_OK
    je   LossNext
    mov  ebx, eax

    mov  edi, batMed[esi*4]
    mov  eax, batQty[esi*4]
    imul eax, medPrice[edi*4]
    mov  ecx, eax

    cmp  ebx, STATUS_EXPIRED
    jne  LossIsSoon
    add  expiredLoss, ecx
    mov  eax, lightRed
    jmp  LossPrint
LossIsSoon:
    add  soonLoss, ecx
    mov  eax, yellow
LossPrint:
    call SetTextColor
    mov  eax, edi
    call PrintMedName
    PrintText msgQtyLabel
    mov  eax, batQty[esi*4]
    call WriteDec
    PrintText msgExpiryLabel
    mov  eax, batExpiry[esi*4]
    call WriteDec
    PrintText msgValueLabel
    mov  eax, ecx
    call WriteDec
    cmp  ebx, STATUS_EXPIRED
    jne  LossTagSoon
    PrintText msgTagExpired
    jmp  LossTagDone
LossTagSoon:
    PrintText msgTagSoon
LossTagDone:
    call Crlf
    mov  eax, white
    call SetTextColor

    inc  lossRows
    cmp  lossRows, ROWS_PER_PAGE
    jl   LossNext
    call WaitMsg
    mov  lossRows, 0
LossNext:
    inc  esi
    jmp  LossLoop

LossLoopDone:
    mov  eax, expiredLoss
    add  eax, soonLoss
    cmp  eax, 0
    jne  PrintLossTotals
    PrintColored lightGreen, msgNoRisk
    ret
PrintLossTotals:
    call Crlf
    PrintColored lightRed, msgExpiredTotal
    mov  eax, expiredLoss
    call WriteDec
    call Crlf
    PrintColored yellow, msgSoonTotal
    mov  eax, soonLoss
    call WriteDec
    call Crlf
    PrintColored lightCyan, msgRiskTotal
    mov  eax, expiredLoss
    add  eax, soonLoss
    call WriteDec
    call Crlf
    ret
ExpiryLossReport ENDP

; Reorder Suggestion: low-stock medicines, fast sellers first
ReorderSuggestion PROC USES eax ebx ecx edx esi edi
    PrintColored yellow, msgReorderHead

    mov  lowCount, 0
    mov  esi, 0
CollectLoop:
    cmp  esi, medCount
    jge  CollectDone
    mov  eax, esi
    call GetUsableStock
    cmp  eax, LOW_STOCK_LIMIT
    jge  CollectNext
    mov  edi, lowCount
    mov  lowList[edi*4], esi
    inc  lowCount
CollectNext:
    inc  esi
    jmp  CollectLoop

CollectDone:
    cmp  lowCount, 0
    jne  SortLowList
    PrintColored lightGreen, msgAllGood
    ret

SortLowList:
    mov  ecx, lowCount
    dec  ecx
    jz   PrintSuggestions
ROuterLoop:
    push ecx
    mov  esi, 0
RInnerLoop:
    mov  edi, esi
    inc  edi
    cmp  edi, lowCount
    jge  RInnerDone
    mov  eax, lowList[esi*4]
    mov  ebx, lowList[edi*4]
    mov  edx, medSold[eax*4]
    cmp  edx, medSold[ebx*4]
    jge  RNoSwap
    mov  lowList[esi*4], ebx
    mov  lowList[edi*4], eax
RNoSwap:
    inc  esi
    jmp  RInnerLoop
RInnerDone:
    pop  ecx
    dec  ecx
    jnz  ROuterLoop

PrintSuggestions:
    mov  edi, 0
RPrintLoop:
    cmp  edi, lowCount
    jge  RPrintDone
    mov  esi, lowList[edi*4]

    mov  eax, esi
    call PrintMedName
    PrintText msgUsableLabel
    mov  eax, esi
    call GetUsableStock
    mov  ecx, eax
    call WriteDec
    PrintText msgSoldLabel
    mov  eax, medSold[esi*4]
    call WriteDec

    mov  eax, medSold[esi*4]
    mov  edx, 0
    mov  ebx, 10
    div  ebx
    mov  ebx, TARGET_STOCK
    sub  ebx, ecx
    add  eax, ebx
    PrintColored lightGreen, msgOrderLabel
    call WriteDec
    call Crlf

    inc  edi
    jmp  RPrintLoop
RPrintDone:
    ret
ReorderSuggestion ENDP

; Daily Sales Report: bills, items sold, total sales and highest bill
DailySalesReport PROC USES eax
    PrintColored lightCyan, msgSalesHeader
    PrintText msgSalesDate
    mov  eax, todayDate
    call WriteDec
    call Crlf
    PrintText msgSalesBills
    mov  eax, billCount
    call WriteDec
    call Crlf
    PrintText msgSalesItems
    mov  eax, itemsSold
    call WriteDec
    call Crlf
    PrintText msgSalesTotal
    mov  eax, totalSales
    call WriteDec
    call Crlf
    PrintText msgSalesMax
    mov  eax, maxBill
    call WriteDec
    call Crlf
    ret
DailySalesReport ENDP

; Save and Load file: all data is stored in a binary file
; SaveQuiet writes the file without messages. EAX = 1 on success, 0 on failure
SaveQuiet PROC USES ecx edx
    mov  edx, OFFSET dataFileName
    call CreateOutputFile
    cmp  eax, INVALID_HANDLE_VALUE
    jne  FileCreated
    mov  eax, 0
    ret
FileCreated:
    mov  fileHandle, eax
    WriteBlock medCount,  COUNTERS_SIZE
    WriteBlock medID,     MAX_MEDICINES * 4
    WriteBlock medName,   MAX_MEDICINES * NAME_SIZE
    WriteBlock medPrice,  MAX_MEDICINES * 4
    WriteBlock medSold,   MAX_MEDICINES * 4
    WriteBlock batMed,    MAX_BATCHES * 4
    WriteBlock batQty,    MAX_BATCHES * 4
    WriteBlock batExpiry, MAX_BATCHES * 4
    mov  eax, fileHandle
    call CloseFile
    mov  eax, 1
    ret
SaveQuiet ENDP

; Called after every change so data is never lost if the window is closed
AutoSave PROC USES eax
    call SaveQuiet
    cmp  eax, 1
    je   AutoSaved
    PrintColored lightRed, msgSaveError
AutoSaved:
    ret
AutoSave ENDP

SaveDataToFile PROC USES eax
    call SaveQuiet
    cmp  eax, 1
    jne  SaveFailed
    PrintColored lightGreen, msgSaved
    ret
SaveFailed:
    PrintColored lightRed, msgSaveError
    ret
SaveDataToFile ENDP

LoadDataFromFile PROC USES eax ecx edx
    mov  edx, OFFSET dataFileName
    call OpenInputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   NoFileYet
    mov  fileHandle, eax
    ReadBlock medCount,  COUNTERS_SIZE
    ReadBlock medID,     MAX_MEDICINES * 4
    ReadBlock medName,   MAX_MEDICINES * NAME_SIZE
    ReadBlock medPrice,  MAX_MEDICINES * 4
    ReadBlock medSold,   MAX_MEDICINES * 4
    ReadBlock batMed,    MAX_BATCHES * 4
    ReadBlock batQty,    MAX_BATCHES * 4
    ReadBlock batExpiry, MAX_BATCHES * 4
    mov  eax, fileHandle
    call CloseFile

    cmp  medCount, MAX_MEDICINES
    ja   CorruptFile
    cmp  batCount, MAX_BATCHES
    ja   CorruptFile
    ret
CorruptFile:
    mov  medCount, 0
    mov  batCount, 0
    mov  billCount, 0
    mov  itemsSold, 0
    mov  totalSales, 0
    mov  maxBill, 0
    mov  lastSaleDate, 0
NoFileYet:
    ret
LoadDataFromFile ENDP

END main
