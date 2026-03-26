package com.example.chat.service;

import com.example.chat.model.dto.MessageResponse;
import com.example.chat.model.entity.ChatMessage;
import com.example.chat.model.entity.ChatMessageDocument;
import com.example.chat.repository.ChatMessageSearchRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class SearchService {

    private final ChatMessageSearchRepository searchRepository;

    public SearchService(ChatMessageSearchRepository searchRepository) {
        this.searchRepository = searchRepository;
    }

    public void indexMessage(ChatMessage message) {
        searchRepository.save(new ChatMessageDocument(message));
    }

    public Page<MessageResponse> searchMessages(UUID roomId, String query, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return searchRepository
                .findByRoomIdAndContentContaining(roomId.toString(), query, pageable)
                .map(doc -> new MessageResponse(
                        UUID.fromString(doc.getId()),
                        doc.getSenderId(),
                        doc.getSenderName(),
                        doc.getContent(),
                        doc.getMessageType(),
                        doc.getCreatedAt()
                ));
    }
}
