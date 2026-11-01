--[[
  BucketListLocale.lua
  ---------------------
  Table de traduction de BucketList, selectionnee automatiquement selon
  GetLocale() (langue du client WoW), avec repli sur l'anglais si une cle
  manque pour la langue detectee.

  IMPORTANT : GetLocale() ne renvoie jamais "jaJP" -- il n'existe pas de
  client WoW officiellement localise en japonais (les joueurs japonais
  utilisent enUS, koKR ou zhTW). Le japonais n'est donc pas propose ici en
  detection automatique.

  Doit etre charge AVANT BucketList.lua (voir BucketList.toc).
]]

local STRINGS = {}

STRINGS.en = {
  TITLE = "My Bucket List",
  ADD_BUTTON = "Add",
  PLACEHOLDER = "Enter a goal...",
  MOVE_UP = "Move Up",
  MOVE_DOWN = "Move Down",
  DELETE = "Delete",
  CANCEL = "Cancel",
  CONFIRM_DELETE_FMT = "Delete \"%s\" from the bucket list?",
  SHARE_HEADER = "My Bucket List:\n",
}

STRINGS.fr = {
  TITLE = "Ma Bucket List",
  ADD_BUTTON = "Ajouter",
  PLACEHOLDER = "Entrez un objectif...",
  MOVE_UP = "Monter",
  MOVE_DOWN = "Descendre",
  DELETE = "Supprimer",
  CANCEL = "Annuler",
  CONFIRM_DELETE_FMT = "Supprimer \"%s\" de la bucket list ?",
  SHARE_HEADER = "Ma Bucket List :\n",
}

STRINGS.es = {
  TITLE = "Mi Lista de Objetivos",
  ADD_BUTTON = "Añadir",
  PLACEHOLDER = "Introduce un objetivo...",
  MOVE_UP = "Subir",
  MOVE_DOWN = "Bajar",
  DELETE = "Eliminar",
  CANCEL = "Cancelar",
  CONFIRM_DELETE_FMT = "¿Eliminar \"%s\" de la lista?",
  SHARE_HEADER = "Mi Lista de Objetivos:\n",
}

STRINGS.pt = {
  TITLE = "Minha Lista de Objetivos",
  ADD_BUTTON = "Adicionar",
  PLACEHOLDER = "Digite um objetivo...",
  MOVE_UP = "Subir",
  MOVE_DOWN = "Descer",
  DELETE = "Excluir",
  CANCEL = "Cancelar",
  CONFIRM_DELETE_FMT = "Excluir \"%s\" da lista?",
  SHARE_HEADER = "Minha Lista de Objetivos:\n",
}

STRINGS.ru = {
  TITLE = "Мой список целей",
  ADD_BUTTON = "Добавить",
  PLACEHOLDER = "Введите цель...",
  MOVE_UP = "Вверх",
  MOVE_DOWN = "Вниз",
  DELETE = "Удалить",
  CANCEL = "Отмена",
  CONFIRM_DELETE_FMT = "Удалить «%s» из списка?",
  SHARE_HEADER = "Мой список целей:\n",
}

STRINGS.de = {
  TITLE = "Meine Bucket List",
  ADD_BUTTON = "Hinzufügen",
  PLACEHOLDER = "Ziel eingeben...",
  MOVE_UP = "Nach oben",
  MOVE_DOWN = "Nach unten",
  DELETE = "Löschen",
  CANCEL = "Abbrechen",
  CONFIRM_DELETE_FMT = "\"%s\" aus der Bucket List löschen?",
  SHARE_HEADER = "Meine Bucket List:\n",
}

STRINGS.it = {
  TITLE = "La mia Bucket List",
  ADD_BUTTON = "Aggiungi",
  PLACEHOLDER = "Inserisci un obiettivo...",
  MOVE_UP = "Sposta su",
  MOVE_DOWN = "Sposta giù",
  DELETE = "Elimina",
  CANCEL = "Annulla",
  CONFIRM_DELETE_FMT = "Eliminare \"%s\" dalla bucket list?",
  SHARE_HEADER = "La mia Bucket List:\n",
}

STRINGS.ko = {
  TITLE = "내 버킷리스트",
  ADD_BUTTON = "추가",
  PLACEHOLDER = "목표를 입력하세요...",
  MOVE_UP = "위로",
  MOVE_DOWN = "아래로",
  DELETE = "삭제",
  CANCEL = "취소",
  CONFIRM_DELETE_FMT = "\"%s\"을(를) 목록에서 삭제하시겠습니까?",
  SHARE_HEADER = "내 버킷리스트:\n",
}

STRINGS.zhCN = {
  TITLE = "我的愿望清单",
  ADD_BUTTON = "添加",
  PLACEHOLDER = "输入一个目标...",
  MOVE_UP = "上移",
  MOVE_DOWN = "下移",
  DELETE = "删除",
  CANCEL = "取消",
  CONFIRM_DELETE_FMT = "确定从清单中删除“%s”吗？",
  SHARE_HEADER = "我的愿望清单：\n",
}

STRINGS.zhTW = {
  TITLE = "我的願望清單",
  ADD_BUTTON = "新增",
  PLACEHOLDER = "輸入一個目標...",
  MOVE_UP = "上移",
  MOVE_DOWN = "下移",
  DELETE = "刪除",
  CANCEL = "取消",
  CONFIRM_DELETE_FMT = "確定從清單中刪除「%s」嗎？",
  SHARE_HEADER = "我的願望清單：\n",
}

-- Les 11 valeurs possibles de GetLocale() (confirme via Warcraft Wiki,
-- API GetLocale) : enUS, koKR, frFR, deDE, zhCN, esES, zhTW, esMX, ruRU,
-- ptBR, itIT. Toutes couvertes ci-dessous (enUS utilise le repli anglais
-- par defaut, pas de table dediee).
local locale = GetLocale()
local LANG = "en"
if locale == "frFR" then LANG = "fr"
elseif locale == "esES" or locale == "esMX" then LANG = "es"
elseif locale == "ptBR" then LANG = "pt"
elseif locale == "ruRU" then LANG = "ru"
elseif locale == "koKR" then LANG = "ko"
elseif locale == "zhCN" then LANG = "zhCN"
elseif locale == "zhTW" then LANG = "zhTW"
elseif locale == "deDE" then LANG = "de"
elseif locale == "itIT" then LANG = "it"
end

-- Table exposee globalement pour BucketList.lua (charge juste apres, voir
-- BucketList.toc).
BucketListL = setmetatable({}, {
  __index = function(_, key)
    return STRINGS[LANG][key] or STRINGS.en[key] or key
  end
})
