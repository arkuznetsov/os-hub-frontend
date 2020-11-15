&Идентификатор
&ГенерируемоеЗначение
&Колонка(Тип = "Целое")
Перем Код Экспорт;

Перем УчетнаяЗапись Экспорт;

Перем Имя Экспорт;

Перем ЭлектроннаяПочта Экспорт;

&Сущность(ИмяТаблицы = "Авторы")
Процедура ПриСозданииОбъекта(пКод = Неопределено)

	Если ЗначениеЗаполнено(пКод) Тогда
		Объект = МенеджерБазыДанных.АвторыМенеджер.ПолучитьОдно(пКод);	
		Если ЗначениеЗаполнено(Объект) Тогда
			ЗаполнитьЗначенияСвойств(ЭтотОбъект, Объект);
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

Функция НайтиАвтораПоИмени(МенеджерСущностей, ИмяАвтора) Экспорт

	Перем Автор;

	Отбор = Новый Соответствие;
	Отбор.Вставить("Имя", ИмяАвтора);
	РезультатПоиска = МенеджерСущностей.Получить(Тип("Автор"), Отбор);
	Если РезультатПоиска.Количество() > 0 Тогда
		Автор = РезультатПоиска[0];
	КонецЕсли;

	Возврат Автор;

КонецФункции

Функция Пустой() Экспорт
	Возврат Не ЗначениеЗаполнено(Код);
КонецФункции
