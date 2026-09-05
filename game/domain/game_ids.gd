class_name GameIds
extends RefCounted

## Wire IDs are append-only. Never reorder a released enum.
enum Item { LAMP, FUSE }
enum Action { PICK_LAMP, PICK_FUSE, INSTALL_FUSE, PLACE_LAMP, RADIO, GREET, PROMISE, FINISH }
enum Outcome { OK, INVALID, UNAVAILABLE, FULL, NEED_ITEM, NEED_POWER, NEED_CONTACT, NOT_READY, DONE, DENIED }

const INVENTORY_SLOTS: int = 3
const MAX_PLAYERS: int = 4
const SERVER_ID: int = 1
const DEFAULT_PORT: int = 28740
const REQUEST_WINDOW_MS: int = 1000
const REQUESTS_PER_WINDOW: int = 8
const PROFILE_PATH: String = "res://content/guests/027_waiting.tres"

const ITEM_LABELS: Dictionary = {Item.LAMP: "Лампа", Item.FUSE: "Предохранитель"}
const ACTION_LABELS: Dictionary = {
	Action.PICK_LAMP: "Взять переносную лампу",
	Action.PICK_FUSE: "Взять предохранитель",
	Action.INSTALL_FUSE: "Восстановить питание",
	Action.PLACE_LAMP: "Поставить лампу у кресла",
	Action.RADIO: "Переключить радио",
	Action.GREET: "Представиться / восстановить контакт",
	Action.PROMISE: "Обещать вернуться",
	Action.FINISH: "Сдать смену",
}
const OUTCOME_LABELS: Dictionary = {
	Outcome.OK: "Принято.",
	Outcome.INVALID: "Неизвестное действие.",
	Outcome.UNAVAILABLE: "Это уже сделано или предмет забрали.",
	Outcome.FULL: "В инвентаре нет места.",
	Outcome.NEED_ITEM: "Сначала возьмите нужный предмет на посту.",
	Outcome.NEED_POWER: "Сначала восстановите питание у щитка.",
	Outcome.NEED_CONTACT: "Сначала представьтесь подопечной.",
	Outcome.NOT_READY: "Нужны питание, лампа, радио и спокойная подопечная.",
	Outcome.DONE: "Смена принята. Сегодня никто не остался один.",
	Outcome.DENIED: "Действие отклонено сервером.",
}
