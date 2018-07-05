#Использовать restler
#Использовать logos
#Использовать fs
#Использовать json

Перем Лог;

Перем ТокенАвторизации;
Перем мКаталогСкачивания;
Перем КартаИмен;


Функция ПолучитьСоединениеGithub()
	Сервер = "https://api.github.com";
	_Соединение = Новый HTTPСоединение(Сервер);
	
	Возврат _Соединение;
КонецФункции

Функция ПолучитьЗаголовкиЗапросаGithub()
	
	_Заголовки = Новый Соответствие();
	_Заголовки.Вставить("Accept", "application/vnd.github.v3+json");
	_Заголовки.Вставить("User-Agent", "oscript-library-autobuilder");
	Если Не ПустаяСтрока(ТокенАвторизации) Тогда
		_Заголовки.Вставить("Authorization", СтрШаблон("token %1", ТокенАвторизации));
	КонецЕсли;

	Возврат _Заголовки;
	
КонецФункции

Функция ПрочестьСекретныйПараметр(ИмяПараметра)

	ЗначениеПеременной = ПолучитьПеременнуюСреды(ИмяПараметра);
	Возврат Строка(ЗначениеПеременной); // неопределено в строку

КонецФункции

Процедура Инициализация(Знач КаталогСкачивания) Экспорт
	ПарсерJSON = Новый ПарсерJSON;
	мКаталогСкачивания = КаталогСкачивания;
	ФС.ОбеспечитьКаталог(КаталогСкачивания);
	Лог = Логирование.ПолучитьЛог("oscript.hub-backend.log");
	ТокенАвторизации = ПрочестьСекретныйПараметр("GITHUB_AUTH_TOKEN");
	ПрочитатьКартуИмен();
КонецПроцедуры

Процедура ПрочитатьКартуИмен()
	ФайлКарты = ОбъединитьПути(СтартовыйСценарий().Каталог, "nameRemap.json");
	
	Если ФС.ФайлСуществует(ФайлКарты) Тогда
		КартаИмен = ОбщегоНазначения.ПрочитатьJson(ФайлКарты);
	Иначе
		ВызватьИсключение "АА";
		КартаИмен = Новый Соответствие;
	КонецЕсли;

КонецПроцедуры

Процедура СоздатьФайлыОписаний() Экспорт

	Соединение = ПолучитьСоединениеGithub();
	Заголовки = ПолучитьЗаголовкиЗапросаGithub();

	КлиентВебAPI = Новый КлиентВебAPI();
	КлиентВебAPI.ИспользоватьСоединение(Соединение);
	КлиентВебAPI.УстановитьЗаголовки(Заголовки);

	РесурсСписокРепозиториев = "/orgs/oscript-library/repos";

	Лог.Информация("Запрашиваю список репозиториев");
	СписокРепозиториев = КлиентВебAPI.Получить(РесурсСписокРепозиториев);	
	Навигатор = Новый НавигаторСтраниц(КлиентВебAPI);
	Пока Истина Цикл
		СохранитьФайлОписанияДляПорции(СписокРепозиториев, КлиентВебAPI);
		Лог.Информация("Получаю очередную порцию");
		СписокРепозиториев = Навигатор.Получить("next");
		Если СписокРепозиториев = Неопределено Тогда
			Лог.Информация("Нет следующей порции. Выход");
			Прервать;
		КонецЕсли
	КонецЦикла;

КонецПроцедуры

Процедура СохранитьФайлОписанияДляПорции(Знач СписокРепозиториев, Знач КлиентВебAPI)
	Для Каждого ДанныеРепозитория Из СписокРепозиториев Цикл
		
		Лог.Информация("Получаю README для " + ДанныеРепозитория["name"]);
		АдресОписанияREADME = СтрШаблон("/repos/oscript-library/%1/readme", ДанныеРепозитория["name"]);
		Лог.Информация("Адрес README: %1", АдресОписанияREADME);
		Попытка
			Описание = КлиентВебAPI.Получить(АдресОписанияREADME);
		Исключение
			Лог.Ошибка("Не удалось получить описание для " + ДанныеРепозитория["name"] + "
			|" + ОписаниеОшибки());
		КонецПопытки;
		
		ПутьКФайлу = Новый Файл(
			ОбъединитьПути(мКаталогСкачивания,
				ДанныеРепозитория["name"],
				"readme.md")
		);

		Если Не ФС.КаталогСуществует(ПутьКФайлу.Путь) Тогда
			ПутьПоКарте = КартаИмен[ДанныеРепозитория["name"]];
			Если ПутьПоКарте <> Неопределено Тогда
				ПутьКФайлу = Новый Файл(
					ОбъединитьПути(мКаталогСкачивания,
						ПутьПоКарте,
						"readme.md")
				);
			КонецЕсли;

			Если Не ФС.КаталогСуществует(ПутьКФайлу.Путь) Тогда
				Лог.Информация("Пропускаю репо %1, т.к. целевой каталог отсутствует",ДанныеРепозитория["name"]);
				Продолжить;
			КонецЕсли;
		КонецЕсли;

		Двоичные = base64Значение(Описание["content"]);
		Двоичные.Записать(ПутьКФайлу.ПолноеИмя);
	КонецЦикла;
КонецПроцедуры

Процедура ОбновитьКешПакетов() Экспорт
	Соединение = ПолучитьСоединениеGithub();
	Заголовки = ПолучитьЗаголовкиЗапросаGithub();

	КлиентВебAPI = Новый КлиентВебAPI();
	КлиентВебAPI.ИспользоватьСоединение(Соединение);
	КлиентВебAPI.УстановитьЗаголовки(Заголовки);

	РесурсСписокРепозиториев = "/orgs/oscript-library/repos";

	Лог.Отладка("Запрашиваю список репозиториев");
	СписокРепозиториев = КлиентВебAPI.Получить(РесурсСписокРепозиториев);
	Навигатор = Новый НавигаторСтраниц(КлиентВебAPI);
	Таблица            = ПереченьПакетов.ПолучитьПакеты();

	Пока Истина Цикл

		ОбработатьПорциюОписаний(Таблица, СписокРепозиториев);

		Лог.Отладка("Запрашиваю следующую порцию");
		СписокРепозиториев = Навигатор.Получить("next");

		Если СписокРепозиториев = Неопределено Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Лог.Информация("Сохраняю кеш");

	СохранитьКешПакетов(Таблица);

КонецПроцедуры

Процедура ОбработатьПорциюОписаний(Знач Таблица, Знач СписокРепозиториев)
	Для Каждого ДанныеРепозитория Из СписокРепозиториев Цикл
		Лог.Отладка("Получаю URL для " + ДанныеРепозитория["name"]);
		Адрес = ДанныеРепозитория["html_url"];
		Лог.Отладка("Получен адрес репо: " + Адрес);
		СтрокаОписания = Таблица.Найти(ДанныеРепозитория["name"], "Название");
		Если СтрокаОписания <> Неопределено Тогда
			СтрокаОписания.АдресРепозитория = Адрес;
		Иначе
			ИмяПоКарте = КартаИмен[ДанныеРепозитория["name"]];
			СтрокаОписания = Таблица.Найти(ИмяПоКарте, "Название");
			Если СтрокаОписания <> Неопределено Тогда
				СтрокаОписания.АдресРепозитория = Адрес;
			Иначе
				Лог.Предупреждение("Не найдено описание пакета для %1", Адрес);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры

Процедура СохранитьКешПакетов(Знач Таблица)
	СтруктураСтроки = Новый Структура;
	Для Каждого Колонка Из Таблица.Колонки Цикл
		СтруктураСтроки.Вставить(Колонка.Имя);
	КонецЦикла;

	Парсер = Новый ПарсерJSON;
	Для Каждого СтрокаОписания Из Таблица Цикл
		Лог.Отладка("Запись кеша для %1", СтрокаОписания.Название);
		ПутьМета = ОбъединитьПути(СтрокаОписания.ПутьХранения,"meta.json");
		ЗаполнитьЗначенияСвойств(СтруктураСтроки, СтрокаОписания,,"Версии,АктуальнаяВерсия");
		СтруктураСтроки.Версии = Новый Массив;
		Для Каждого Версия Из СтрокаОписания.Версии Цикл
			СтруктураСтроки.Версии.Добавить(Версия.ВСтроку());
		КонецЦикла;
		Если СтрокаОписания.АктуальнаяВерсия <> Неопределено Тогда
			СтруктураСтроки.АктуальнаяВерсия = СтрокаОписания.АктуальнаяВерсия.ВСтроку();
		КонецЕсли;

		Контент = Парсер.ЗаписатьJSON(СтруктураСтроки);
		ЗаписьТекста = Новый ЗаписьТекста(ПутьМета);
		ЗаписьТекста.Записать(Контент);
		ЗаписьТекста.Закрыть();
	КонецЦикла;
КонецПроцедуры