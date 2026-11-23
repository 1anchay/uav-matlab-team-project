function [channel, delivered] = advanced_comms_step(channel, packet, tick, cfg)
%ADVANCED_COMMS_STEP 05: delayed and lossy downlink with sequence numbers.
% Stateless across simulations: channel is passed in and out explicitly.
% Packet can be [] to flush the queue on a later tick.
if isempty(channel)
    channel.pending = struct('due',{},'packet',{});
    channel.sent = 0;
    channel.lost = 0;
    channel.deliveredCount = 0;
    channel.delaySamples = zeros(1,0);
    channel.lastPacket = [];
end
delivered = [];
% Release packets already in flight; the channel is FIFO for equal due times.
keep = true(1,numel(channel.pending));
for k = 1:numel(channel.pending)
    if channel.pending(k).due <= tick
        delivered = channel.pending(k).packet;
        channel.deliveredCount = channel.deliveredCount+1;
        channel.delaySamples(end+1) = tick-delivered.sampleTick; %#ok<AGROW>
        channel.lastPacket = delivered;
        keep(k) = false;
    end
end
channel.pending = channel.pending(keep);

if ~isempty(packet)
    channel.sent = channel.sent+1;
    packet.sequence = channel.sent;
    packet.sampleTick = tick;
    if rand < cfg.advanced.packetLossProbability
        channel.lost = channel.lost+1;
    else
        release.due = tick+cfg.advanced.packetLatencySteps;
        release.packet = packet;
        channel.pending(end+1) = release;
    end
end
end
