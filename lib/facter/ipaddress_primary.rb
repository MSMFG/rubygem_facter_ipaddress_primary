# ipaddress_primary.rb
require 'socket'

# Determine closest NICs to target addresses and provide a default NIC
class AdjacentNicTool
  # As good as any address for adjacent NIC address test
  AWS_INSTANCE_METADATA_ADDRESS = '169.254.169.254'.freeze

  # The main NIC determined adjacent to the meta address
  def self.default_nic_address
    adjacent_local(AWS_INSTANCE_METADATA_ADDRESS)
  end

  def self.nic_translation
    nictable = Socket.getifaddrs.map do |nic|
      next unless nic.addr.ipv4?
      [nic.addr.ip_address, nic.name]
    end
    Hash[nictable.compact]
  end

  def self.default_nic
    nic_translation[default_nic_address]
  end

  # Find closest NIC address to target if we have multiple NICs
  # (reliable local NIC determination)
  # Note: UDP Sockets do NOT send anything on connect
  #       but DO work out what source address will be
  #       used so the port number is irrelevant to this
  #       mechanism.
  def self.adjacent_local(addr)
    dummy_sock = UDPSocket.new
    dummy_sock.connect(addr, 1)
    _fam, _port, _name, addr = dummy_sock.addr
    addr
  end
end

Facter.add(:ipaddress_primary) do
  confine kernel: %w[Linux FreeBSD OpenBSD SunOS HP-UX Darwin GNU/kFreeBSD]
  setcode do
    AdjacentNicTool.default_nic_address
  end
end

Facter.add(:primary_nic) do
  confine kernel: %w[Linux FreeBSD OpenBSD SunOS HP-UX Darwin GNU/kFreeBSD]
  setcode do
    AdjacentNicTool.default_nic
  end
end
