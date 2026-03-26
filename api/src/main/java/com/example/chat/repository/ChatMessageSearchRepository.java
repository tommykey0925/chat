package com.example.chat.repository;

import com.example.chat.model.entity.ChatMessageDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

public interface ChatMessageSearchRepository extends ElasticsearchRepository<ChatMessageDocument, String> {

    Page<ChatMessageDocument> findByRoomIdAndContentContaining(String roomId, String content, Pageable pageable);
}
