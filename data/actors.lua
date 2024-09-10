local actors = {}

local interacted_objects_blacklist = {}

-- Nova tabela para objetos que não queremos ignorar permanentemente
local temporary_ignore_objects = {}

-- Tempo de expiração em segundos para objetos temporariamente ignorados
local expiration_time = 10 -- 60 segundos, ajuste conforme necessário

-- Nova tabela para objetos que não queremos interagir
local ignored_objects = {
    "Lilith",
    "QST_Class_Necro_Shrine",
    "LE_Shrine_Goatman_Props_Arrangement_SP",
    "fxKit_seamlessSphere_twoSided2_lilithShrine_idle",
    "LE_Shrine_Zombie_Props_Arrangement_SP",
    "_Shrine_Moss_"
}

-- Função para verificar se um objeto deve ser ignorado
local function should_ignore_object(skin_name)
    for _, ignored_pattern in ipairs(ignored_objects) do
        if skin_name:match(ignored_pattern) then
            return true
        end
    end
    return false
end

-- Tabela para definir diferentes tipos de atores e suas configurações
local actor_types = {
    shrine = {
        pattern = "Shrine_",
        move_threshold = 12,
        interact_threshold = 2.5,
        interact_function = function(obj) 
            interact_object(obj)
        end
    },
    goblin = {
        pattern = "treasure_goblin",
        move_threshold = 20,
        interact_threshold = 2,
        interact_function = function(actor)
            console.print("Interacting with the Goblin")
        end
    },
    harvest_node = {
        pattern = "HarvestNode_Ore",
        move_threshold = 12,
        interact_threshold = 1.0,
        interact_function = function(obj)
            interact_object(obj)
        end
    },
    Misterious_Chest = {
        pattern = "Hell_Prop_Chest_Rare_Locked",
        move_threshold = 12,
        interact_threshold = 1.0,
        interact_function = function(obj)
            interact_object(obj)
        end
    },
    Herbs = {
        pattern = "HarvestNode_Herb",
        move_threshold = 8,
        interact_threshold = 1.0,
        interact_function = function(obj)
            interact_object(obj)
        end
    }
    -- Adicione mais tipos de atores conforme necessário
}

-- Modificar a função is_actor_of_type para usar a nova lógica de ignorar objetos
local function is_actor_of_type(skin_name, actor_type)
    return skin_name:match(actor_types[actor_type].pattern) and not should_ignore_object(skin_name)
end

local function should_interact_with_actor(actor_position, player_position, actor_type)
    local distance_threshold = actor_types[actor_type].interact_threshold
    return actor_position:dist_to(player_position) < distance_threshold
end

local function move_to_actor(actor_position, player_position, actor_type)
    local move_threshold = actor_types[actor_type].move_threshold
    local distance = actor_position:dist_to(player_position)
    
    if distance <= move_threshold then
        pathfinder.request_move(actor_position)
        --console.print("Detected " .. actor_type .. " at " .. distance .. " units. Moving towards.")
        return true
    end
    
    return false
end

function actors.update()
    local local_player = get_local_player()
    if not local_player then
        return
    end

    local player_pos = local_player:get_position()
    local all_actors = actors_manager.get_all_actors()
    local current_time = os.clock()

    -- Limpar objetos expirados da lista de ignorados temporários
    for id, timestamp in pairs(temporary_ignore_objects) do
        if current_time - timestamp > expiration_time then
            temporary_ignore_objects[id] = nil
        end
    end

    -- Ordenar atores por distância
    table.sort(all_actors, function(a, b)
        return a:get_position():squared_dist_to_ignore_z(player_pos) <
               b:get_position():squared_dist_to_ignore_z(player_pos)
    end)

    for _, obj in ipairs(all_actors) do
        if obj and not temporary_ignore_objects[obj:get_id()] then
            local position = obj:get_position()
            local skin_name = obj:get_skin_name()

            for actor_type, config in pairs(actor_types) do
                if skin_name and is_actor_of_type(skin_name, actor_type) and not obj:can_not_interact() then
                    local distance = position:dist_to(player_pos)
                    if distance <= config.move_threshold then
                        if move_to_actor(position, player_pos, actor_type) then
                            --console.print("Moving towards the " .. actor_type .. ": " .. skin_name)
                            if should_interact_with_actor(position, player_pos, actor_type) then
                                config.interact_function(obj)
                                temporary_ignore_objects[obj:get_id()] = current_time
                                console.print("Interacted with the " .. actor_type .. ": " .. skin_name)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Função para limpar a lista de objetos ignorados temporariamente
function actors.clear_temporary_ignore_list()
    temporary_ignore_objects = {}
    console.print("Cleared temporary ignore objects list")
end

return actors