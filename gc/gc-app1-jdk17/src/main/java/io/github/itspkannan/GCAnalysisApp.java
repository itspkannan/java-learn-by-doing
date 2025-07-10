package io.github.itspkannan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GCAnalysisApp {
    public static void main(String[] args) {
        SpringApplication.run(GCAnalysisApp.class, args);

        new Thread(() -> {
            while (true) {
                byte[] data = new byte[10 * 1024 * 1024];
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }).start();
    }
}
