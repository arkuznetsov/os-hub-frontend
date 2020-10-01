#Использовать entity

Перем МенеджерСущностей Экспорт;

Процедура Инициализировать() Экспорт
	
	СтрокаПодключения = ПолучитьПеременнуюСреды("OSWEB_DATABASE__CONNECTIONSTRING");
	МенеджерСущностей = Новый МенеджерСущностей(Тип("КоннекторPostgreSQL"), СтрокаПодключения);

	МенеджерСущностей.ДобавитьКлассВМодель(Тип("Автор"));
	МенеджерСущностей.ДобавитьКлассВМодель(Тип("Зависимость"));
	МенеджерСущностей.ДобавитьКлассВМодель(Тип("Пакет"));
	МенеджерСущностей.ДобавитьКлассВМодель(Тип("ВерсияПакета"));
	МенеджерСущностей.Инициализировать();
	
КонецПроцедуры