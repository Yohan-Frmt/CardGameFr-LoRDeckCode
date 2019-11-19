require 'base32'

MAX_KNOWN_VERSION = 1

class VarIntTransformer
  def self.popVarInt bytes
    allButMSB, justMSB, result, current_shift, bytes_popped = 0x7F, 0x80, 0, 0, 0
    bytes.each_with_index do |byte, index|
      bytes_popped += 1
      current = byte & allButMSB
      result |= current << current_shift
      if index & justMSB != justMSB
        bytes.slice! 0, bytes_popped
        return result
      end
      current_shift += 7
    end
    raise 'Byte array did not contain valid variants'
  end

  def self.getVarInt value
    val, allButMSB, justMSB, buff, currentIndex = value.to_i, 0x7f, 0x80, [10], 0
    return [0] if val.zero?
    until val.zero?
      byteVal = val & allButMSB
      val >>= 7
      byteVal |= justMSB if val != 0
      buff[currentIndex] = byteVal
      currentIndex += 1
    end
    buff.slice! 0, currentIndex
  end

  def self.encodeGroupOf groupOf
    bytes = Array.new
    bytes = [*bytes, *VarIntTransformer.getVarInt(groupOf.length)]
    groupOf.each do |group|
      bytes = [*bytes, *VarIntTransformer.getVarInt(group.length)]
      currentCode = group[0]
      current_set_number, current_faction = currentCode[0...2], currentCode[2...4]
      current_faction_number = Factions.getIdFromCode current_faction
      bytes = [*bytes, *VarIntTransformer.getVarInt(current_set_number)]
      bytes = [*bytes, *VarIntTransformer.getVarInt(current_faction_number)]
      group.each do |gr|
        bytes = [*bytes, *VarIntTransformer.getVarInt(gr[4...7].to_i)]
      end
    end
    bytes
  end

  def self.encodeNOfs nOfs
    bytes = Array.new
    nOfs.each do |hash|
      bytes = [*bytes, *VarIntTransformer.getVarInt(hash[:count])]
      code = hash[:code]
      set_number, faction, card_number = code[0...2], code[2...4],  code[4...7]
      faction_number = Factions.getIdFromCode faction
      bytes = [*bytes, *VarIntTransformer.getVarInt(set_number)]
      bytes = [*bytes, *VarIntTransformer.getVarInt(faction_number)]
      bytes = [*bytes, *VarIntTransformer.getVarInt(card_number)]
    end
    bytes
  end
end

class Factions
  def self.getIdFromCode code
    case code
    when 'DE' then 0
    when 'FR' then 1
    when 'IO' then 2
    when 'NX' then 3
    when 'PZ' then 4
    when 'SI' then 5
    end
  end

  def self.getCodeFromId id
    case id
    when 0 then 'DE'
    when 1 then 'FR'
    when 2 then 'IO'
    when 3 then 'NX'
    when 4 then 'PZ'
    when 5 then 'SI'
    end
  end
end

class LorDeckCode
  def self.encode deck
    result, cards_1, cards_2, cards_3, cards_N = [17], Array.new, Array.new, Array.new, Array.new
    raise 'Deck contains invalid card codes' unless LorDeckCode.isValidCardCodesAndCounts deck
    deck.each do |h|
      case h[:count]
      when 3 then cards_3.push h[:code]
      when 2 then cards_2.push h[:code]
      when 1 then cards_1.push h[:code]
      when h[:count] < 1 then raise "Invalid count (#{h[:count]}) for card code '#{h[:code]}'"
      else cards_N.push h
      end
    end
    grouped_cards_1 = LorDeckCode.getGroupsByCountsOfs cards_1
    grouped_cards_2 = LorDeckCode.getGroupsByCountsOfs cards_2
    grouped_cards_3 = LorDeckCode.getGroupsByCountsOfs cards_3
    sortGroup = ->(groups) { groups.each { |group| group.sort_by! { |c| c } }.reverse! }
    sortGroup.call grouped_cards_1
    sortGroup.call grouped_cards_2
    sortGroup.call grouped_cards_3
    cards_N = cards_N.sort
    result = [*result, *VarIntTransformer.encodeGroupOf(grouped_cards_3)]
    result = [*result, *VarIntTransformer.encodeGroupOf(grouped_cards_2)]
    result = [*result, *VarIntTransformer.encodeGroupOf(grouped_cards_1)]
    result = [*result, *VarIntTransformer.encodeNOfs(cards_N)]
    Base32.encode result.pack('U*')
  end

  def self.decode deckCode
    result = Array.new
    byte_list = Base32.decode(deckCode).bytes.to_a
    format = byte_list[0] >> 4
    version = byte_list[0] & 0xF
    byte_list.shift
    raise 'Please update to the latest version of encoder' if version > MAX_KNOWN_VERSION
    3.downto 1 do |n|
      numberGroupOfs = VarIntTransformer.popVarInt byte_list
      numberGroupOfs.times do
        numberOfsInGroup, set_number, faction = VarIntTransformer.popVarInt(byte_list), VarIntTransformer.popVarInt(byte_list), VarIntTransformer.popVarInt(byte_list)
        numberOfsInGroup.times do
          card = VarIntTransformer.popVarInt byte_list
          set_string = '0' + set_number.to_s
          set_string[0] = '' while set_string.length > 2
          faction_string = Factions.getCodeFromId faction
          card_string = '00' + card.to_s
          card_string[0] = '' while card_string.length > 3
          card_code = set_string + faction_string + card_string
          result << {:code => card_code, :count => n}
        end
      end
    end

    while byte_list.length > 0 do
      fpc, fps, fpf, fpn = VarIntTransformer.popVarInt(byte_list), VarIntTransformer.popVarInt(byte_list), VarIntTransformer.popVarInt(byte_list), VarIntTransformer.popVarInt(byte_list)
      fpss = '0' + fps.to_s
      fpss[0] = '' while fpss.length > 2
      fpfs = Factions.getIdFromCode fpf
      fpns = '00' + fpn.to_s
      fpns[0] = '' while fpns.length > 3
      card_code = fpss + fpfs + fpns
      result << {:code => card_code, :count => fpc}
    end
    result
  end

  def self.getGroupsByCountsOfs list
    new_list = Array.new
    until list.empty?
      card = list[0]
      list.shift
      set_number, faction, faction_set, tmp = card[0...2], card[2...4], Array.new, Array.new(list)
      faction_set.push card
      tmp.each do |card|
        currentSetNumber, currentFaction = card[0...2], card[2...4]
        if currentSetNumber == set_number && currentFaction == faction
          faction_set.push card
          list.delete card
        end
      end
      faction_set.sort
      new_list.push faction_set
    end
    new_list
  end

  def self.isValidCardCodesAndCounts deck
    deck.each do |h|
      faction = h[:code][2...4]
      false if h[:code].length != 7
      false unless /\d\d/.match?(h[:code][0...2])
      false if Factions.getIdFromCode(faction).nil?
      false unless /\d\d\d/.match?(h[:code][4...7])
      false if h[:count] < 1
    end
  end
end